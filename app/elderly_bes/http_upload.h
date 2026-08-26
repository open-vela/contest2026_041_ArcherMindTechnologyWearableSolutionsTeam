/****************************************************************************
 * apps/examples/elderly_bes/http_upload.h
 *
 * HTTP 数据上报模块接口。
 ****************************************************************************/

#ifndef __HTTP_UPLOAD_H
#define __HTTP_UPLOAD_H

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * 初始化 HTTP 上传模块。
 */

void http_upload_init(void);

/**
 * 上传体征数据。
 * @param json JSON 格式的体征数据
 * @return 0 成功, -1 失败
 */

int http_upload_vitals(const char *json);

/**
 * 上传报警事件。
 * @param json JSON 格式的报警数据
 * @return 0 成功, -1 失败
 */

int http_upload_alarm(const char *json);

/**
 * 上传设备心跳。
 * @param json JSON 格式的心跳数据
 * @return 0 成功, -1 失败
 */

int http_upload_heartbeat(const char *json);

/**
 * 注册设备到服务器。
 * @param device_sn 设备序列号
 * @param device_name 设备名称
 * @return 0 成功, -1 失败
 */

int http_device_register(const char *device_sn, const char *device_name);

#endif /* __HTTP_UPLOAD_H */
