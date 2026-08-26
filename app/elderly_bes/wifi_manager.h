/****************************************************************************
 * apps/examples/elderly_bes/wifi_manager.h
 *
 * WiFi 管理器：扫描、连接、状态查询。
 ****************************************************************************/

#ifndef __WIFI_MANAGER_H
#define __WIFI_MANAGER_H

#include "ui_common.h"

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

#define WIFI_MAX_SSID_LEN   33
#define WIFI_MAX_SCAN       16
#define WIFI_MAX_PASS_LEN   64

/****************************************************************************
 * Public Type Definitions
 ****************************************************************************/

/* WiFi 网络信息 */

typedef struct
{
  char ssid[WIFI_MAX_SSID_LEN];   /* 网络名称 */
  int  rssi;                       /* 信号强度 (dBm) */
  int  encrypt;                    /* 加密类型 (0=开放, 3=WPA2) */
} wifi_ap_info_t;

/* WiFi 连接状态 */

typedef enum
{
  WIFI_STATUS_DISCONNECTED = 0,
  WIFI_STATUS_CONNECTING,
  WIFI_STATUS_CONNECTED,
  WIFI_STATUS_FAILED
} wifi_status_t;

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * 初始化 WiFi 管理器。
 */

void wifi_manager_init(void);

/**
 * 扫描周围 WiFi 网络。
 * 返回找到的网络数量。
 */

int wifi_manager_scan(void);

/**
 * 获取扫描结果。
 * @param index 索引 (0 ~ count-1)
 * @param info  输出网络信息
 * @return 0 成功, -1 失败
 */

int wifi_manager_get_ap(int index, wifi_ap_info_t *info);

/**
 * 获取扫描到的网络数量。
 */

int wifi_manager_get_scan_count(void);

/**
 * 连接到指定 WiFi 网络。
 * @param ssid     网络名称
 * @param password 密码 (开放网络传空字符串)
 * @return 0 成功, -1 失败
 */

int wifi_manager_connect(const char *ssid, const char *password);

/**
 * 断开 WiFi 连接。
 */

void wifi_manager_disconnect(void);

/**
 * 获取当前连接状态。
 */

wifi_status_t wifi_manager_get_status(void);

/**
 * 获取当前连接的 SSID。
 * 未连接时返回空字符串。
 */

const char *wifi_manager_get_ssid(void);

/**
 * 获取当前 IP 地址。
 * 未连接时返回空字符串。
 */

const char *wifi_manager_get_ip(void);

/**
 * 获取状态字符串。
 */

const char *wifi_manager_get_status_str(void);

#endif /* __WIFI_MANAGER_H */
