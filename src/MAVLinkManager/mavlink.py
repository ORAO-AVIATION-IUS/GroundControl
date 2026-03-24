from pymavlink import mavutil
import time
import random

# C++ uygulaman 14550 portunu dinlediği için 'udpout' kullanıyoruz
master = mavutil.mavlink_connection('udpout:localhost:14550')

print("Simülasyon başlatıldı. Veriler 1.5 saniyede bir güncelleniyor...")

while True:
    # --- RASTGELE VERİ ÜRETİMİ ---
    random_mode_id = random.choice([0, 2, 5, 10, 11, 15])
    pitch_val = random.uniform(-20, 20)
    roll_val = random.uniform(-45, 45)
    heading_val = random.randint(0, 359)
    alt_val = random.uniform(10, 500)
    batt_val = random.randint(10, 100)
    airspeed_val = random.uniform(15.0, 35.0)
    
    # G-Kuvveti (m/s^2 bazında ham değerler)
    accel_x = random.randint(-100, 100)
    accel_y = random.randint(-100, 100)
    accel_z = -9806 + random.randint(-200, 200) 
    
    # Jiroskop (rad/s * 1000)
    gyro_x = random.randint(-100, 100)
    gyro_y = random.randint(-100, 100)
    gyro_z = random.randint(-100, 100)

    # 1. HEARTBEAT
    master.mav.heartbeat_send(
        mavutil.mavlink.MAV_TYPE_FIXED_WING,
        mavutil.mavlink.MAV_AUTOPILOT_ARDUPILOTMEGA,
        mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
        random_mode_id, 
        mavutil.mavlink.MAV_STATE_ACTIVE
    )

    # 2. ATTITUDE
    master.mav.attitude_send(
        int(time.time() * 1000) % 4294967295,
        roll_val * 0.0174533,
        pitch_val * 0.0174533,
        heading_val * 0.0174533,
        0, 0, 0
    )

    # 3. VFR_HUD
    master.mav.vfr_hud_send(
        airspeed_val, airspeed_val, heading_val, 50, alt_val, 0.5
    )

    # 4. SYS_STATUS
    master.mav.sys_status_send(
        0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 500, 12600, 1000, 
        int(batt_val), 0, 0, 0, 0, 0, 0
    )

    # 5. RAW_IMU (Düzeltilen Kısım)
    # Parametreler: time_usec, xacc, yacc, zacc, xgyro, ygyro, zgyro, xmag, ymag, zmag
    master.mav.raw_imu_send(
        int(time.time() * 1e6),
        accel_x, accel_y, accel_z, # Ivme
        gyro_x, gyro_y, gyro_z,    # Jiroskop
        0, 0, 0                     # Manyetometre (opsiyonel)
    )

    print(f"--- VERİ GÖNDERİLDİ ---")
    print(f"Hız: {airspeed_val:.1f} m/s | Heading: {heading_val}° | G: {abs(accel_z)/9806:.2f}")
    
    time.sleep(1.5)