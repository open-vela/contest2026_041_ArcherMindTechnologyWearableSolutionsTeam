/****************************************************************************
 * apps/examples/elderly_bes/http_upload.c
 *
 * HTTP 数据上报模块：体征数据、报警事件、设备心跳。
 * 通过 NuttX POSIX socket 实现 HTTP POST。
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "http_upload.h"
#include "ui_common.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

#define HTTP_HOST           "101.35.231.154"
#define HTTP_PORT           80
#define HTTP_TIMEOUT_SEC    5
#define HTTP_BUF_SIZE       2048

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/**
 * 发送 HTTP POST 请求
 */

static int http_post_json(const char *path, const char *json,
                          char *resp_buf, int resp_size)
{
  int fd;
  struct sockaddr_in addr;
  struct hostent *he;
  struct timeval tv;
  char request[HTTP_BUF_SIZE];
  int ret;
  int offset;
  int total;

  /* 创建 socket */

  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0)
    {
      LV_LOG_USER("[HTTP] socket() failed");
      return -1;
    }

  /* 设置超时 */

  tv.tv_sec = HTTP_TIMEOUT_SEC;
  tv.tv_usec = 0;
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
  setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

  /* 连接服务器 */

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(HTTP_PORT);

  /* 尝试 DNS 解析，失败则用 IP */

  he = gethostbyname(HTTP_HOST);
  if (he != NULL)
    {
      memcpy(&addr.sin_addr, he->h_addr, he->h_length);
    }
  else
    {
      inet_pton(AF_INET, HTTP_HOST, &addr.sin_addr);
    }

  ret = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
  if (ret < 0)
    {
      LV_LOG_USER("[HTTP] connect() failed");
      close(fd);
      return -1;
    }

  /* 构建 HTTP 请求 */

  int json_len = (json != NULL) ? (int)strlen(json) : 0;

  offset = snprintf(request, sizeof(request),
                    "POST %s HTTP/1.1\r\n"
                    "Host: %s\r\n"
                    "Content-Type: application/json; charset=utf-8\r\n"
                    "Connection: close\r\n"
                    "Content-Length: %d\r\n"
                    "\r\n",
                    path, HTTP_HOST, json_len);

  if (json != NULL && json_len > 0)
    {
      memcpy(request + offset, json, json_len);
      offset += json_len;
    }

  /* 发送请求 */

  int sent = 0;
  while (sent < offset)
    {
      int n = send(fd, request + sent, offset - sent, 0);
      if (n <= 0)
        {
          LV_LOG_USER("[HTTP] send() failed");
          close(fd);
          return -1;
        }
      sent += n;
    }

  /* 接收响应 */

  total = 0;
  if (resp_buf != NULL && resp_size > 0)
    {
      while (total < resp_size - 1)
        {
          int n = recv(fd, resp_buf + total, resp_size - 1 - total, 0);
          if (n <= 0)
            break;
          total += n;
        }
      resp_buf[total] = '\0';
    }

  close(fd);
  return total > 0 ? 0 : -1;
}

/**
 * 提取 HTTP 状态码
 */

static int parse_status_code(const char *resp)
{
  if (resp == NULL || strncmp(resp, "HTTP/", 5) != 0)
    return -1;

  const char *p = strchr(resp, ' ');
  if (p == NULL)
    return -1;

  return atoi(p + 1);
}

/**
 * 提取 HTTP body
 */

static const char *parse_body(const char *resp)
{
  const char *body = strstr(resp, "\r\n\r\n");
  return body ? (body + 4) : NULL;
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

void http_upload_init(void)
{
  LV_LOG_USER("[HTTP] Upload module initialized (server: %s:%d)",
              HTTP_HOST, HTTP_PORT);
}

int http_upload_vitals(const char *json)
{
  char resp[512];
  int ret;

  LV_LOG_USER("[HTTP] Uploading vitals...");

  ret = http_post_json("/api/v1/vitals", json, resp, sizeof(resp));
  if (ret == 0)
    {
      int status = parse_status_code(resp);
      const char *body = parse_body(resp);
      LV_LOG_USER("[HTTP] Vitals response: %d %s",
                  status, body ? body : "(empty)");
      return (status >= 200 && status < 300) ? 0 : -1;
    }

  LV_LOG_USER("[HTTP] Vitals upload failed");
  return -1;
}

int http_upload_alarm(const char *json)
{
  char resp[512];
  int ret;

  LV_LOG_USER("[HTTP] Uploading alarm...");

  ret = http_post_json("/api/v1/alarms", json, resp, sizeof(resp));
  if (ret == 0)
    {
      int status = parse_status_code(resp);
      const char *body = parse_body(resp);
      LV_LOG_USER("[HTTP] Alarm response: %d %s",
                  status, body ? body : "(empty)");
      return (status >= 200 && status < 300) ? 0 : -1;
    }

  LV_LOG_USER("[HTTP] Alarm upload failed");
  return -1;
}

int http_upload_heartbeat(const char *json)
{
  char resp[512];
  int ret;

  LV_LOG_USER("[HTTP] Uploading heartbeat...");

  /* 心跳使用 vitals 接口，附带 heartbeat 标记 */

  ret = http_post_json("/api/v1/vitals", json, resp, sizeof(resp));
  if (ret == 0)
    {
      int status = parse_status_code(resp);
      LV_LOG_USER("[HTTP] Heartbeat response: %d", status);
      return (status >= 200 && status < 300) ? 0 : -1;
    }

  return -1;
}

int http_device_register(const char *device_sn, const char *device_name)
{
  char json[256];
  char resp[512];
  int ret;

  snprintf(json, sizeof(json),
           "{\"device_sn\":\"%s\",\"device_name\":\"%s\",\"device_type\":\"smartwatch\"}",
           device_sn, device_name);

  LV_LOG_USER("[HTTP] Registering device %s...", device_sn);

  ret = http_post_json("/api/v1/devices", json, resp, sizeof(resp));
  if (ret == 0)
    {
      int status = parse_status_code(resp);
      const char *body = parse_body(resp);
      LV_LOG_USER("[HTTP] Register response: %d %s",
                  status, body ? body : "(empty)");
      return (status >= 200 && status < 300) ? 0 : -1;
    }

  LV_LOG_USER("[HTTP] Device registration failed");
  return -1;
}
