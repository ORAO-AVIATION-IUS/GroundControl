from pymavlink import mavutil
import time
import random

# C++ uygulaman 14550 portunu dinlediği için 'udpout' kullanıyoruz
master = mavutil.mavlink_connection('udpout:localhost:14550')

print("Simülasyon başlatıldı. Veriler 2 saniyede bir güncelleniyor...")


while True:
    #rastgele bir mod için rastgele sayı çekyiyoz
    random_mode_id = random.choice([0, 2, 5, 10, 11, 15])

    master.mav.heartbeat_send(
        mavutil.mavlink.MAV_TYPE_FIXED_WING,
        mavutil.mavlink.MAV_AUTOPILOT_ARDUPILOTMEGA,
        mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
        random_mode_id, 
        mavutil.mavlink.MAV_STATE_ACTIVE
    )

    pitch_val = random.uniform(-20, 20)    # -20 ile +20 derece
    roll_val = random.uniform(-45, 45)     # -45 ile +45 derece
    heading_val = random.randint(0, 359)   # 0-359 derece (Heading)
    alt_val = random.uniform(10, 500)      # 10-500 metre (Altitude)
    batt_val = random.randint(10, 100)     # %10-%100 (Battery)
    
    # 2. ATTITUDE (Pitch, Roll, Yaw)
    # Parametreler: boot_ms, roll(rad), pitch(rad), yaw(rad), hızlar...
    master.mav.attitude_send(
        int(time.time() * 1000) % 4294967295,
        roll_val * 0.0174533,  # Dereceyi radyana çevir
        pitch_val * 0.0174533,
        heading_val * 0.0174533,
        0, 0, 0
    )

    # 3. VFR_HUD (Heading, Altitude, Speed)
    # Heading ve Altitude bilgilerini esas olarak buradan çekeriz
    master.mav.vfr_hud_send(
        20.5,           # airspeed
        20.5,           # groundspeed
        heading_val,    # heading (derece)
        50,             # throttle
        alt_val,        # alt
        0.5             # climb
    )

    # 4. SYS_STATUS (Battery)
    # battery_remaining (6. parametre) % cinsinden veridir
    master.mav.sys_status_send(
    0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 
    500,          # CPU Load
    12600,        # 12.6V (mV)
    1000,         # 1000mA
    int(batt_val),# İŞTE BURASI (% kalan batarya)
    0, 0, 0, 0, 0, 0
)
    print(f"VERİ GÖNDERİLDİ (Mod: {random_mode_id}) ---")
    print(f"Pitch: {pitch_val:.1f} | Roll: {roll_val:.1f} | Heading: {heading_val}")
    print(f"Alt: {alt_val:.1f}m | Batarya: %{batt_val}")
    
    # 2 saniye bekle 
    time.sleep(1.5)