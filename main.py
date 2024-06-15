import sys
import psutil
import time
import threading
from ctypes import POINTER, cast
from PyQt5.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QPushButton, QComboBox, QLabel, QCheckBox
from PyQt5.QtCore import Qt
from pycaw.pycaw import AudioUtilities, IAudioMeterInformation, ISimpleAudioVolume
import spotipy
from spotipy.oauth2 import SpotifyOAuth
import vlc
import win32com.client
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Spotify credentials from .env file
SPOTIPY_CLIENT_ID = os.getenv('SPOTIPY_CLIENT_ID')
SPOTIPY_CLIENT_SECRET = os.getenv('SPOTIPY_CLIENT_SECRET')
SPOTIPY_REDIRECT_URI = os.getenv('SPOTIPY_REDIRECT_URI')

# Event to signal thread termination
terminate_event = threading.Event()

class SoundManagerApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.initUI()
        self.target_app_name = None
        self.simple_audio = None
        self.sp = spotipy.Spotify(auth_manager=SpotifyOAuth(
            client_id=SPOTIPY_CLIENT_ID,
            client_secret=SPOTIPY_CLIENT_SECRET,
            redirect_uri=SPOTIPY_REDIRECT_URI,
            scope="user-modify-playback-state user-read-playback-state"))
        self.vlc_instance = vlc.Instance()
        self.vlc_player = self.vlc_instance.media_player_new()

    def initUI(self):
        self.setWindowTitle('Hush')
        self.setGeometry(100, 100, 400, 200)

        layout = QVBoxLayout()

        self.label = QLabel("Select the application to manage volume:", self)
        layout.addWidget(self.label)

        self.app_combo_box = QComboBox(self)
        layout.addWidget(self.app_combo_box)

        self.pause_checkbox = QCheckBox("Pause music instead of lowering volume", self)
        layout.addWidget(self.pause_checkbox)

        self.refresh_button = QPushButton('Refresh Applications', self)
        self.refresh_button.clicked.connect(self.refresh_app_list)
        layout.addWidget(self.refresh_button)

        self.start_button = QPushButton('Start Monitoring', self)
        self.start_button.clicked.connect(self.start_monitoring)
        layout.addWidget(self.start_button)

        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

        self.refresh_app_list()

    def refresh_app_list(self):
        self.app_combo_box.clear()
        processes = self.get_running_media_players()
        added_apps = set()
        for process in processes:
            if process.name() not in added_apps:
                self.app_combo_box.addItem(process.name(), process.name())
                added_apps.add(process.name())

    def get_running_media_players(self):
        media_players = ['spotify.exe', 'itunes.exe', 'wmplayer.exe', 'vlc.exe', 'foobar2000.exe', 'musicbee.exe', 'groove.exe']
        running_media_players = []
        for proc in psutil.process_iter(['pid', 'name']):
            try:
                if proc.info['name'].lower() in media_players:
                    running_media_players.append(proc)
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        return running_media_players

    def start_monitoring(self):
        selected_name = self.app_combo_box.currentData()
        if selected_name:
            self.target_app_name = selected_name.lower()
            print(f"Selected application: {self.target_app_name}")
            monitor_thread = threading.Thread(target=self.monitor_sounds)
            monitor_thread.start()

    def monitor_sounds(self):
        previous_active = False
        pause_music = self.pause_checkbox.isChecked()
        wait_time = 2  # Time to wait in seconds

        while not terminate_event.is_set():
            active_sound_apps = self.get_active_sound_applications()
            target_session = self.get_target_session()
            if target_session:
                self.simple_audio = target_session._ctl.QueryInterface(ISimpleAudioVolume)
                if active_sound_apps and not previous_active:
                    print(f"Active sound apps detected: {active_sound_apps}.")
                    if pause_music:
                        print(f"Pausing {self.target_app_name}.")
                        self.pause_music()
                    else:
                        print(f"Lowering {self.target_app_name} volume.")
                        smooth_volume_change(self.simple_audio, self.simple_audio.GetMasterVolume(), 0.1)
                    previous_active = True
                elif not active_sound_apps and previous_active:
                    print(f"No active sound apps detected. Waiting for {wait_time} seconds.")
                    time.sleep(wait_time)
                    active_sound_apps = self.get_active_sound_applications()
                    if not active_sound_apps:
                        if pause_music:
                            print(f"Resuming {self.target_app_name}.")
                            self.resume_music()
                        else:
                            print(f"Restoring {self.target_app_name} volume.")
                            smooth_volume_change(self.simple_audio, self.simple_audio.GetMasterVolume(), 1.0)
                        previous_active = False
            else:
                print(f"{self.target_app_name} is not running.")
            time.sleep(1)

    def get_active_sound_applications(self):
        active_sound_apps = []
        sessions = AudioUtilities.GetAllSessions()
        for session in sessions:
            try:
                if session.Process and session.Process.name().lower() != self.target_app_name and is_audio_playing(session):
                    active_sound_apps.append(session.Process.name())
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                pass
        return active_sound_apps

    def get_target_session(self):
        sessions = AudioUtilities.GetAllSessions()
        for session in sessions:
            if session.Process and session.Process.name().lower() == self.target_app_name:
                return session
        return None

    def pause_music(self):
        if self.target_app_name == 'spotify.exe':
            try:
                devices = self.sp.devices()
                active_devices = [d for d in devices['devices'] if d['is_active']]
                if not active_devices:
                    print("No active Spotify device found.")
                    return
                self.sp.pause_playback()
            except Exception as e:
                print(f"Error pausing Spotify: {e}")
        elif self.target_app_name == 'vlc.exe':
            try:
                self.vlc_player.pause()
            except Exception as e:
                print(f"Error pausing VLC: {e}")
        elif self.target_app_name == 'wmplayer.exe':
            try:
                wmp = win32com.client.Dispatch("WMPlayer.OCX")
                wmp.controls.pause()
            except Exception as e:
                print(f"Error pausing Windows Media Player: {e}")
        else:
            print(f"Pausing not implemented for {self.target_app_name}")

    def resume_music(self):
        if self.target_app_name == 'spotify.exe':
            try:
                devices = self.sp.devices()
                active_devices = [d for d in devices['devices'] if d['is_active']]
                if not active_devices:
                    print("No active Spotify device found.")
                    return
                self.sp.start_playback()
            except Exception as e:
                print(f"Error resuming Spotify: {e}")
        elif self.target_app_name == 'vlc.exe':
            try:
                self.vlc_player.play()
            except Exception as e:
                print(f"Error resuming VLC: {e}")
        elif self.target_app_name == 'wmplayer.exe':
            try:
                wmp = win32com.client.Dispatch("WMPlayer.OCX")
                wmp.controls.play()
            except Exception as e:
                print(f"Error resuming Windows Media Player: {e}")
        else:
            print(f"Resuming not implemented for {self.target_app_name}")

    def closeEvent(self, event):
        print("Exiting... Please wait.")
        terminate_event.set()
        if self.simple_audio:
            print("Restoring volume to default.")
            smooth_volume_change(self.simple_audio, self.simple_audio.GetMasterVolume(), 1.0)
        event.accept()
        print("Exited cleanly.")

def smooth_volume_change(volume_control, start_volume, end_volume, duration=1.0):
    steps = 50
    step_duration = duration / steps
    volume_step = (end_volume - start_volume) / steps

    for step in range(steps):
        if terminate_event.is_set():
            break
        current_volume = start_volume + step * volume_step
        volume_control.SetMasterVolume(current_volume, None)
        time.sleep(step_duration)
    
    volume_control.SetMasterVolume(end_volume, None)

def is_audio_playing(session):
    meter = session._ctl.QueryInterface(IAudioMeterInformation)
    peak = meter.GetPeakValue()
    return peak > 0.01

if __name__ == '__main__':
    app = QApplication(sys.argv)
    ex = SoundManagerApp()
    ex.show()

    try:
        sys.exit(app.exec_())
    except KeyboardInterrupt:
        print("Exiting... Please wait.")
        terminate_event.set()
        print("Exited cleanly.")
