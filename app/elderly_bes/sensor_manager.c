/****************************************************************************
 * apps/examples/elderly_bes/sensor_manager.c
 *
 * 传感器管理器：BMI270 数据采集、跌倒检测、步数统计、姿态识别。
 * 传感器未连接时使用模拟数据，确保应用可独立运行。
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "sensor_manager.h"
#include <math.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

/* 跌倒检测阈值 */

#define FREEFALL_THRESH     3.0f    /* 自由落体: 合加速度 < 3 m/s² */
#define IMPACT_THRESH       25.0f   /* 撞击: 合加速度 > 25 m/s² */
#define FALL_TIME_WINDOW_MS 1500    /* 自由落体→撞击 时间窗口 (ms) */
#define FALL_CONFIRM_MS     2000    /* 跌倒确认后持续时间 (ms) */
#define FALL_COOLDOWN_MS    10000   /* 跌倒报警冷却时间 (ms) */

/* 步数检测阈值 */

#define STEP_ACCEL_THRESH   1.5f    /* 步行加速度变化阈值 (m/s²) */
#define STEP_MIN_INTERVAL   250     /* 最小步间隔 (ms) */
#define STEP_MAX_INTERVAL   2000    /* 最大步间隔 (ms) */

/* 姿态检测阈值 (基于重力分量) */

#define STANDING_Z_THRESH   7.0f    /* 站立: Z > 7 */
#define LYING_Z_THRESH      3.0f    /* 躺下: Z < 3 */
#define WALKING_GYRO_THRESH 30.0f   /* 行走: 角速度 > 30°/s */

/* 模拟数据参数 */

#define SIM_ACCEL_BASE      9.81f   /* 重力加速度 */
#define SIM_STEP_PERIOD     600     /* 模拟步行周期 (ms) */

/****************************************************************************
 * Private Data
 ****************************************************************************/

static sensor_data_t g_sensor;
static bool g_connected = false;
static bool g_initialized = false;

/* 跌倒检测状态 */

static uint64_t g_freefall_start = 0;
static uint64_t g_last_fall_time = 0;

/* 步数检测状态 */

static float g_step_last_peak = 0;
static float g_step_last_valley = 0;
static bool g_step_in_peak = false;
static uint64_t g_step_last_time = 0;

/* 姿态历史 (用于平滑) */

static posture_type_t g_posture_history[4] =
{
  POSTURE_STANDING,
  POSTURE_STANDING,
  POSTURE_STANDING,
  POSTURE_STANDING
};
static int g_posture_idx = 0;

/* 模拟数据状态 */

static uint64_t g_sim_start = 0;
static int32_t g_sim_steps = 0;

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/**
 * 获取当前时间戳 (ms)
 */

static uint64_t get_time_ms(void)
{
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint64_t)ts.tv_sec * 1000 + (uint64_t)ts.tv_nsec / 1000000;
}

/**
 * 计算加速度合值
 */

static float calc_accel_magnitude(float ax, float ay, float az)
{
  return sqrtf(ax * ax + ay * ay + az * az);
}

/**
 * 计算角速度合值
 */

static float calc_gyro_magnitude(float gx, float gy, float gz)
{
  return sqrtf(gx * gx + gy * gy + gz * gz);
}

/**
 * 跌倒检测算法
 *
 * 检测模式: 自由落体 → 撞击
 *   1. 合加速度突然降到 < 3 m/s² (自由落体)
 *   2. 在 1.5s 内合加速度突然升到 > 25 m/s² (撞击)
 *   3. 确认跌倒
 */

static void detect_fall(sensor_data_t *data)
{
  uint64_t now = get_time_ms();
  float mag = data->accel_magnitude;

  /* 冷却期内不检测 */

  if (now - g_last_fall_time < FALL_COOLDOWN_MS)
    {
      data->fall_state = FALL_STATE_RECOVERING;
      data->fall_detected = false;
      return;
    }

  switch (data->fall_state)
    {
      case FALL_STATE_NORMAL:
        /* 检测自由落体 */
        if (mag < FREEFALL_THRESH)
          {
            data->fall_state = FALL_STATE_FREEFALL;
            g_freefall_start = now;
          }
        break;

      case FALL_STATE_FREEFALL:
        /* 检测撞击 (必须在时间窗口内) */
        if (mag > IMPACT_THRESH &&
            (now - g_freefall_start) < FALL_TIME_WINDOW_MS)
          {
            data->fall_state = FALL_STATE_CONFIRMED;
            data->fall_detected = true;
            data->fall_time = now;
            g_last_fall_time = now;
          }
        else if ((now - g_freefall_start) >= FALL_TIME_WINDOW_MS)
          {
            /* 超时，恢复正常 */
            data->fall_state = FALL_STATE_NORMAL;
          }
        else if (mag >= FREEFALL_THRESH && mag <= IMPACT_THRESH)
          {
            /* 过渡阶段，继续等待 */
          }
        else
          {
            /* 加速度恢复正常，非跌倒 */
            data->fall_state = FALL_STATE_NORMAL;
          }
        break;

      case FALL_STATE_CONFIRMED:
      case FALL_STATE_RECOVERING:
        /* 等待冷却 */
        if (now - g_last_fall_time >= FALL_COOLDOWN_MS)
          {
            data->fall_state = FALL_STATE_NORMAL;
            data->fall_detected = false;
          }
        break;
    }
}

/**
 * 步数检测算法
 *
 * 基于加速度信号的峰值检测：
 *   1. 计算合加速度去除重力后的变化量
 *   2. 检测周期性峰值（步行特征）
 *   3. 两次峰值间隔在合理范围内则计一步
 */

static void detect_steps(sensor_data_t *data)
{
  uint64_t now = get_time_ms();
  float mag = data->accel_magnitude;

  /* 去除重力后的加速度变化 */

  float delta = fabsf(mag - SIM_ACCEL_BASE);

  if (delta > STEP_ACCEL_THRESH && !g_step_in_peak)
    {
      /* 进入峰值 */

      g_step_in_peak = true;
      g_step_last_peak = mag;
    }
  else if (delta < STEP_ACCEL_THRESH * 0.5f && g_step_in_peak)
    {
      /* 离开峰值，计一步 */

      g_step_in_peak = false;

      uint64_t interval = now - g_step_last_time;
      if (interval >= STEP_MIN_INTERVAL &&
          interval <= STEP_MAX_INTERVAL)
        {
          data->step_count++;
        }

      g_step_last_time = now;
    }
}

/**
 * 姿态识别算法
 *
 * 基于重力方向判断姿态：
 *   - 站立: Z 轴朝上 (Z ≈ 9.8)
 *   - 坐姿: Z 轴倾斜 (Z ≈ 5-8)
 *   - 平躺: Z 轴水平 (Z ≈ 0, Y ≈ 9.8)
 *   - 侧躺: X 轴朝上 (X ≈ 9.8)
 *   - 行走: 周期性加速度变化 + 角速度
 */

static void detect_posture(sensor_data_t *data)
{
  float ax = data->raw.accel_x;
  float ay = data->raw.accel_y;
  float az = data->raw.accel_z;
  float gyro_mag = data->gyro_magnitude;

  posture_type_t posture = POSTURE_UNKNOWN;

  /* 行走检测优先 (有节奏的加速度变化) */

  if (gyro_mag > WALKING_GYRO_THRESH &&
      data->accel_magnitude > 8.0f &&
      data->accel_magnitude < 12.0f)
    {
      posture = POSTURE_WALKING;
    }
  /* 站立: Z 轴接近重力方向 */

  else if (az > STANDING_Z_THRESH && fabsf(ax) < 4.0f)
    {
      posture = POSTURE_STANDING;
    }
  /* 坐姿: Z 轴倾斜 */

  else if (az > 4.0f && az <= STANDING_Z_THRESH)
    {
      posture = POSTURE_SITTING;
    }
  /* 平躺: Z 轴接近水平，Y 轴朝上 */

  else if (az < LYING_Z_THRESH && fabsf(ay) > 6.0f)
    {
      posture = POSTURE_LYING_FLAT;
    }
  /* 侧躺: X 轴朝上 */

  else if (fabsf(ax) > 6.0f && az < LYING_Z_THRESH)
    {
      posture = POSTURE_LYING_SIDE;
    }
  else
    {
      posture = POSTURE_SITTING; /* 默认坐姿 */
    }

  /* 姿态历史平滑 (取最近 4 次中最多的) */

  g_posture_history[g_posture_idx] = posture;
  g_posture_idx = (g_posture_idx + 1) % 4;

  /* 投票法取最常见姿态 */

  int counts[POSTURE_COUNT] = {0};
  int max_count = 0;
  posture_type_t max_posture = posture;
  for (int i = 0; i < 4; i++)
    {
      int p = g_posture_history[i];
      counts[p]++;
      if (counts[p] > max_count)
        {
          max_count = counts[p];
          max_posture = (posture_type_t)p;
        }
    }

  data->posture = max_posture;
  data->posture_name = sensor_get_posture_name(max_posture);
}

/**
 * 活动强度计算
 */

static void calc_activity_level(sensor_data_t *data)
{
  /* 基于加速度变化和角速度估算活动强度 (0-100) */

  float accel_var = fabsf(data->accel_magnitude - SIM_ACCEL_BASE);
  float gyro_var = data->gyro_magnitude;

  float level = (accel_var * 3.0f + gyro_var * 0.2f);
  if (level > 100.0f) level = 100.0f;
  if (level < 0.0f) level = 0.0f;

  data->activity_level = (int32_t)level;
}

/**
 * 生成模拟传感器数据
 * 当 BMI270 未连接时使用，模拟日常活动
 */

static void generate_simulated_data(sensor_raw_t *raw)
{
  uint64_t now = get_time_ms();
  if (g_sim_start == 0) g_sim_start = now;

  uint64_t elapsed = now - g_sim_start;
  float t = (float)elapsed / 1000.0f;  /* 秒 */

  /* 模拟不同活动阶段 */

  int phase = (elapsed / 30000) % 5;  /* 每 30 秒切换 */

  float base_ax = 0.0f;
  float base_ay = 0.0f;
  float base_az = SIM_ACCEL_BASE;
  float noise_amp = 0.3f;
  float walk_freq = 2.0f;  /* 步行频率 2Hz */

  switch (phase)
    {
      case 0: /* 站立静止 */
        base_ax = 0.2f;
        base_ay = 0.1f;
        base_az = 9.6f;
        noise_amp = 0.2f;
        break;

      case 1: /* 行走 */
        base_ax = sinf(t * walk_freq * 2.0f * M_PI) * 2.0f;
        base_ay = cosf(t * walk_freq * 2.0f * M_PI) * 1.0f;
        base_az = 9.8f + sinf(t * walk_freq * 4.0f * M_PI) * 1.5f;
        noise_amp = 0.5f;
        g_sim_steps++;
        break;

      case 2: /* 坐下 */
        base_ax = 0.1f;
        base_ay = 0.3f;
        base_az = 7.5f;
        noise_amp = 0.15f;
        break;

      case 3: /* 行走 */
        base_ax = sinf(t * walk_freq * 2.0f * M_PI) * 2.5f;
        base_ay = cosf(t * walk_freq * 2.0f * M_PI) * 1.2f;
        base_az = 9.8f + sinf(t * walk_freq * 4.0f * M_PI) * 1.8f;
        noise_amp = 0.6f;
        g_sim_steps++;
        break;

      case 4: /* 平躺休息 (偶尔触发跌倒模拟) */
        if (elapsed % 30000 > 28000)
          {
            /* 模拟跌倒: 自由落体→撞击 */
            base_ax = 0.5f;
            base_ay = 0.3f;
            base_az = 1.0f;  /* 低加速度 = 自由落体 */
            noise_amp = 0.2f;
          }
        else if (elapsed % 30000 > 28500)
          {
            /* 撞击 */
            base_ax = 5.0f;
            base_ay = 3.0f;
            base_az = 28.0f;
            noise_amp = 1.0f;
          }
        else
          {
            base_ax = 0.1f;
            base_ay = 9.5f;
            base_az = 0.3f;
            noise_amp = 0.1f;
          }
        break;
    }

  /* 添加噪声 */

  float noise_x = ((float)(rand() % 1000) / 500.0f - 1.0f) * noise_amp;
  float noise_y = ((float)(rand() % 1000) / 500.0f - 1.0f) * noise_amp;
  float noise_z = ((float)(rand() % 1000) / 500.0f - 1.0f) * noise_amp;

  raw->accel_x = base_ax + noise_x;
  raw->accel_y = base_ay + noise_y;
  raw->accel_z = base_az + noise_z;

  /* 陀螺仪: 行走时有角速度，静止时接近 0 */

  float gyro_base = (phase == 1 || phase == 3) ? 40.0f : 2.0f;
  raw->gyro_x = ((float)(rand() % 1000) / 500.0f - 1.0f) * gyro_base;
  raw->gyro_y = ((float)(rand() % 1000) / 500.0f - 1.0f) * gyro_base;
  raw->gyro_z = ((float)(rand() % 1000) / 500.0f - 1.0f) * gyro_base;

  raw->temperature = 29.0f + ((float)(rand() % 100) / 500.0f);
  raw->timestamp = now;
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

void sensor_manager_init(void)
{
  memset(&g_sensor, 0, sizeof(g_sensor));
  g_sensor.posture = POSTURE_STANDING;
  g_sensor.posture_name = "Standing";
  g_initialized = true;
  g_connected = false;

  LV_LOG_USER("[SENSOR] Sensor manager initialized (simulated mode)");
}

const sensor_data_t *sensor_manager_update(void)
{
  if (!g_initialized)
    {
      return &g_sensor;
    }

  /* 读取传感器数据 (模拟) */

  sensor_raw_t raw;
  generate_simulated_data(&raw);

  g_sensor.raw = raw;

  /* 计算合值 */

  g_sensor.accel_magnitude = calc_accel_magnitude(
      raw.accel_x, raw.accel_y, raw.accel_z);
  g_sensor.gyro_magnitude = calc_gyro_magnitude(
      raw.gyro_x, raw.gyro_y, raw.gyro_z);

  /* 跌倒检测 */

  detect_fall(&g_sensor);

  /* 步数检测 */

  detect_steps(&g_sensor);

  /* 姿态识别 */

  detect_posture(&g_sensor);

  /* 活动强度 */

  calc_activity_level(&g_sensor);

  /* 粗略卡路里估算 (kcal/min → kcal) */
  /* 活动强度每 100 对应约 8 kcal/min */

  g_sensor.calories += (float)g_sensor.activity_level * 0.008f / 60.0f;

  return &g_sensor;
}

const sensor_data_t *sensor_manager_get(void)
{
  return &g_sensor;
}

void sensor_manager_reset_steps(void)
{
  g_sensor.step_count = 0;
  g_sim_steps = 0;
}

void sensor_manager_clear_fall(void)
{
  g_sensor.fall_detected = false;
  g_sensor.fall_state = FALL_STATE_NORMAL;
  g_last_fall_time = 0;
}

const char *sensor_get_posture_name(posture_type_t posture)
{
  switch (posture)
    {
      case POSTURE_STANDING:  return "Standing";
      case POSTURE_SITTING:   return "Sitting";
      case POSTURE_LYING_FLAT: return "Lying";
      case POSTURE_LYING_SIDE: return "Side";
      case POSTURE_WALKING:   return "Walking";
      case POSTURE_RUNNING:   return "Running";
      default:                return "Unknown";
    }
}

bool sensor_manager_is_connected(void)
{
  return g_connected;
}
