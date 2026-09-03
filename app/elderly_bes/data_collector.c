/****************************************************************************
 * apps/examples/elderly_bes/data_collector.c
 *
 * 数据层：集成传感器管理器，提供体征+运动数据给 UI 层。
 * 当前为 stub 模式（模拟数据 + BMI270 模拟）。
 ****************************************************************************/

#include "data_collector.h"
#include "sensor_manager.h"
#include "wifi_manager.h"
#include "http_upload.h"
#include "ui_sos.h"
#include <string.h>
#include <stdlib.h>
#include <time.h>

/****************************************************************************
 * Private Data
 ****************************************************************************/

static app_context_t g_app_ctx;
static int g_update_frame = 0;          /* 帧计数器 */
static int g_heartbeat_counter = 0;     /* 心跳计数器 */

#define VITALS_UPLOAD_INTERVAL  100     /* 每 100 帧上传体征 (~10秒) */
#define HEARTBEAT_INTERVAL      600     /* 每 600 帧上传心跳 (~60秒) */

/****************************************************************************
 * Public Functions
 ****************************************************************************/

app_context_t *app_get_context(void)
{
  return &g_app_ctx;
}

void data_collector_init(void)
{
  memset(&g_app_ctx, 0, sizeof(g_app_ctx));

  g_app_ctx.settings.brightness = 80;
  g_app_ctx.settings.collect_interval = 10;
  g_app_ctx.settings.sos_enabled = true;
  g_app_ctx.settings.fall_detect = true;
  g_app_ctx.settings.use_sim_data = true;

  g_app_ctx.vitals.heart_rate = 72;
  g_app_ctx.vitals.spo2 = 97;
  g_app_ctx.vitals.temperature = 36.5f;
  g_app_ctx.vitals.steps = 0;
  g_app_ctx.vitals.battery = 85;
  g_app_ctx.vitals.device_online = true;

  g_app_ctx.network_connected = false;

  /* 初始化传感器管理器 */

  sensor_manager_init();

  /* 初始化 HTTP 上传 */

  http_upload_init();
}

void data_collector_stop(void)
{
}

void data_collector_trigger_sos(void)
{
  if (g_app_ctx.alarm.active)
    return;

  /* Set alarm state */

  g_app_ctx.alarm.active = true;
  g_app_ctx.alarm.countdown = SOS_COUNTDOWN_SEC;
  strncpy(g_app_ctx.alarm.alarm_type, "SOS",
          sizeof(g_app_ctx.alarm.alarm_type) - 1);

  /* Snapshot current vital signs + sensor data */

  memcpy(&g_app_ctx.alarm.snapshot, &g_app_ctx.vitals,
         sizeof(vital_data_t));
  strncpy(g_app_ctx.alarm.location, "Acquiring...",
          sizeof(g_app_ctx.alarm.location) - 1);

  /* Build alarm JSON and log (upload when network available) */

  const sensor_data_t *sensor = sensor_manager_get();
  char json[512];
  snprintf(json, sizeof(json),
    "{"
    "\"device_sn\":\"%s\","
    "\"alarm_type\":\"SOS\","
    "\"timestamp\":%lu,"
    "\"heart_rate\":%ld,"
    "\"spo2\":%ld,"
    "\"temperature\":%.1f,"
    "\"steps\":%ld,"
    "\"posture\":\"%s\","
    "\"fall_detected\":%s,"
    "\"battery\":%ld"
    "}",
    CONFIG_EXAMPLES_ELDERLY_BES_DEVICE_SN,
    (unsigned long)(g_app_ctx.vitals.timestamp),
    (long)g_app_ctx.vitals.heart_rate,
    (long)g_app_ctx.vitals.spo2,
    (double)g_app_ctx.vitals.temperature,
    (long)sensor->step_count,
    sensor->posture_name ? sensor->posture_name : "Unknown",
    sensor->fall_detected ? "true" : "false",
    (long)g_app_ctx.vitals.battery);

  LV_LOG_USER("[SOS] Alarm data: %s", json);

  /* WiFi 已连接时上传报警数据 */

  if (wifi_manager_get_status() == WIFI_STATUS_CONNECTED)
    {
      http_upload_alarm(json);
    }

  /* Switch to SOS alarm page */

  ui_sos_activate("SOS");
}

/**
 * 更新传感器数据到全局上下文
 * 由 UI 定时器调用
 */

void data_collector_update(void)
{
  const sensor_data_t *sensor = sensor_manager_update();

  /* 同步步数 */

  g_app_ctx.vitals.steps = sensor->step_count;

  /* 更新时间戳 */

  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  g_app_ctx.vitals.timestamp = (uint64_t)ts.tv_sec * 1000 +
                                (uint64_t)ts.tv_nsec / 1000000;

  g_update_frame++;
  g_heartbeat_counter++;

  /* 定期上传体征数据 (WiFi 已连接时) */

  if (g_update_frame >= VITALS_UPLOAD_INTERVAL &&
      wifi_manager_get_status() == WIFI_STATUS_CONNECTED)
    {
      g_update_frame = 0;
      g_app_ctx.network_connected = true;

      char json[512];
      snprintf(json, sizeof(json),
        "{"
        "\"device_sn\":\"%s\","
        "\"timestamp\":%lu,"
        "\"heart_rate\":%ld,"
        "\"spo2\":%ld,"
        "\"temperature\":%.1f,"
        "\"steps\":%ld,"
        "\"battery\":%ld,"
        "\"posture\":\"%s\","
        "\"activity_level\":%ld"
        "}",
        CONFIG_EXAMPLES_ELDERLY_BES_DEVICE_SN,
        (unsigned long)(g_app_ctx.vitals.timestamp),
        (long)g_app_ctx.vitals.heart_rate,
        (long)g_app_ctx.vitals.spo2,
        (double)g_app_ctx.vitals.temperature,
        (long)sensor->step_count,
        (long)g_app_ctx.vitals.battery,
        sensor->posture_name ? sensor->posture_name : "Unknown",
        (long)sensor->activity_level);

      http_upload_vitals(json);
    }

  /* WiFi 状态更新 */

  if (wifi_manager_get_status() != WIFI_STATUS_CONNECTED)
    {
      g_app_ctx.network_connected = false;
    }

  /* 定期上传心跳 (WiFi 已连接时) */

  if (g_heartbeat_counter >= HEARTBEAT_INTERVAL &&
      wifi_manager_get_status() == WIFI_STATUS_CONNECTED)
    {
      g_heartbeat_counter = 0;

      char hb_json[256];
      snprintf(hb_json, sizeof(hb_json),
        "{"
        "\"device_sn\":\"%s\","
        "\"timestamp\":%lu,"
        "\"battery\":%ld,"
        "\"firmware_version\":\"1.0.0\""
        "}",
        CONFIG_EXAMPLES_ELDERLY_BES_DEVICE_SN,
        (unsigned long)(g_app_ctx.vitals.timestamp),
        (long)g_app_ctx.vitals.battery);

      http_upload_heartbeat(hb_json);
    }

  /* 跌倒检测触发 SOS */

  if (sensor->fall_detected && g_app_ctx.settings.fall_detect &&
      !g_app_ctx.alarm.active)
    {
      g_app_ctx.alarm.active = true;
      g_app_ctx.alarm.countdown = SOS_COUNTDOWN_SEC;
      strncpy(g_app_ctx.alarm.alarm_type, "FALL",
              sizeof(g_app_ctx.alarm.alarm_type) - 1);
      memcpy(&g_app_ctx.alarm.snapshot, &g_app_ctx.vitals,
             sizeof(vital_data_t));

      LV_LOG_USER("[FALL] Fall detected! Triggering alarm.");
      ui_sos_activate("FALL");
    }
}

const vital_data_t *data_collector_get_vitals(void)
{
  return &g_app_ctx.vitals;
}

bool data_collector_check_abnormal(const vital_data_t *v)
{
  if (v->heart_rate < HR_LOW || v->heart_rate > HR_HIGH)
    return true;
  if (v->spo2 < SPO2_LOW)
    return true;
  if (v->temperature < TEMP_LOW || v->temperature > TEMP_HIGH)
    return true;
  return false;
}

/****************************************************************************
 * UI 辅助函数
 ****************************************************************************/

const char *get_hr_status(int32_t hr)
{
  if (hr >= HR_LOW && hr <= HR_HIGH) return "Normal";
  else if (hr < HR_LOW) return "Low";
  else return "High";
}

lv_color_t get_hr_status_color(int32_t hr)
{
  if (hr >= HR_LOW && hr <= HR_HIGH) return COLOR_GREEN;
  return COLOR_RED;
}

const char *get_spo2_status(int32_t spo2)
{
  if (spo2 >= SPO2_LOW) return "Normal";
  return "Low";
}

lv_color_t get_spo2_status_color(int32_t spo2)
{
  if (spo2 >= SPO2_LOW) return COLOR_GREEN;
  return COLOR_RED;
}

const char *get_temp_status(float temp)
{
  if (temp >= TEMP_LOW && temp <= TEMP_HIGH) return "Normal";
  else if (temp < TEMP_LOW) return "Low";
  else return "High";
}

lv_color_t get_temp_status_color(float temp)
{
  if (temp >= TEMP_LOW && temp <= TEMP_HIGH) return COLOR_GREEN;
  return COLOR_RED;
}

void apply_card_style(lv_obj_t *obj)
{
  lv_obj_set_style_bg_color(obj, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(obj, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(obj, 12, 0);
  lv_obj_set_style_border_width(obj, 0, 0);
  lv_obj_set_style_pad_all(obj, 8, 0);
}

void apply_rounded_btn_style(lv_obj_t *obj, lv_color_t bg_color)
{
  lv_obj_set_style_bg_color(obj, bg_color, 0);
  lv_obj_set_style_radius(obj, 22, 0);
  lv_obj_set_style_border_width(obj, 0, 0);
}

void create_dot_indicator(lv_obj_t *parent, lv_color_t color,
                          lv_coord_t x, lv_coord_t y)
{
  lv_obj_t *dot = lv_obj_create(parent);
  lv_obj_set_size(dot, 8, 8);
  lv_obj_set_pos(dot, x, y);
  lv_obj_set_style_radius(dot, 4, 0);
  lv_obj_set_style_bg_color(dot, color, 0);
  lv_obj_set_style_border_width(dot, 0, 0);
}
