/****************************************************************************
 * apps/examples/elderly_bes/sensor_manager.h
 *
 * 传感器管理器：BMI270 数据采集、跌倒检测、步数统计、姿态识别。
 * 传感器未连接时使用模拟数据。
 ****************************************************************************/

#ifndef __SENSOR_MANAGER_H
#define __SENSOR_MANAGER_H

#include "ui_common.h"

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

/* 姿态类型 */

typedef enum
{
  POSTURE_UNKNOWN = 0,
  POSTURE_STANDING,       /* 站立 */
  POSTURE_SITTING,        /* 坐姿 */
  POSTURE_LYING_FLAT,     /* 平躺 */
  POSTURE_LYING_SIDE,     /* 侧躺 */
  POSTURE_WALKING,        /* 行走 */
  POSTURE_RUNNING,        /* 跑步 */
  POSTURE_COUNT
} posture_type_t;

/* 跌倒检测状态 */

typedef enum
{
  FALL_STATE_NORMAL = 0,
  FALL_STATE_FREEFALL,    /* 自由落体阶段 */
  FALL_STATE_IMPACT,      /* 撞击阶段 */
  FALL_STATE_CONFIRMED,   /* 确认跌倒 */
  FALL_STATE_RECOVERING   /* 恢复中 */
} fall_state_t;

/* 传感器原始数据 */

typedef struct
{
  float accel_x;          /* 加速度 X (m/s²) */
  float accel_y;          /* 加速度 Y */
  float accel_z;          /* 加速度 Z */
  float gyro_x;           /* 陀螺仪 X (°/s) */
  float gyro_y;           /* 陀螺仪 Y */
  float gyro_z;           /* 陀螺仪 Z */
  float temperature;      /* 温度 (°C) */
  uint64_t timestamp;     /* 时间戳 (ms) */
} sensor_raw_t;

/* 传感器融合结果 */

typedef struct
{
  /* 原始数据 */
  sensor_raw_t raw;

  /* 计算值 */
  float accel_magnitude;  /* 加速度合值 (m/s²) */
  float gyro_magnitude;   /* 角速度合值 (°/s) */

  /* 姿态 */
  posture_type_t posture;
  const char *posture_name;

  /* 步数 */
  int32_t step_count;

  /* 跌倒检测 */
  fall_state_t fall_state;
  bool fall_detected;     /* 跌倒报警标志 */
  uint64_t fall_time;     /* 跌倒时间戳 */

  /* 活动强度 (0-100) */
  int32_t activity_level;

  /* 卡路里 (粗略估算, kcal) */
  float calories;
} sensor_data_t;

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * 初始化传感器管理器。
 * 尝试打开 BMI270，失败则使用模拟数据。
 */

void sensor_manager_init(void);

/**
 * 更新传感器数据（每帧调用一次）。
 * 返回最新的传感器融合结果。
 */

const sensor_data_t *sensor_manager_update(void);

/**
 * 获取当前传感器数据（不更新）。
 */

const sensor_data_t *sensor_manager_get(void);

/**
 * 重置步数。
 */

void sensor_manager_reset_steps(void);

/**
 * 清除跌倒报警。
 */

void sensor_manager_clear_fall(void);

/**
 * 获取姿态名称字符串。
 */

const char *sensor_get_posture_name(posture_type_t posture);

/**
 * 检查传感器是否已连接。
 */

bool sensor_manager_is_connected(void);

#endif /* __SENSOR_MANAGER_H */
