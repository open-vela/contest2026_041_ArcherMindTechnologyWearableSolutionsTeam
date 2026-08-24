/****************************************************************************
 * apps/examples/elderly/http_client.c
 *
 * HTTP client module for communicating with the elderly health backend API.
 * Uses POSIX sockets for HTTP/HTTPS communication.
 *
 * NOTE: When CONFIG_NET is not enabled, all functions return -ENOSYS.
 * The application works in offline mode (simulated data only).
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "http_client.h"
#include <nuttx/config.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#ifdef CONFIG_NET
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <fcntl.h>
#endif

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

#define HTTP_PORT           80
#define HTTPS_PORT          443
#define HTTP_TIMEOUT_SEC    10
#define HTTP_MAX_HOST       128
#define HTTP_MAX_REQUEST    2048
#define CRLF                "\r\n"

#ifndef CONFIG_EXAMPLES_ELDERLY_BES_SERVER_URL
#define CONFIG_EXAMPLES_ELDERLY_BES_SERVER_URL "http://101.35.231.154/api/v1"
#endif

/****************************************************************************
 * Private Data
 ****************************************************************************/

static char g_server_host[HTTP_MAX_HOST];
static int  g_server_port;
static bool g_use_https;

/****************************************************************************
 * Private Functions
 ****************************************************************************/

#ifdef CONFIG_NET

/**
 * Parse URL into host, port, and path components.
 */

static int parse_url(const char *url, char *host, int *port, char *path,
                     bool *https)
{
  const char *p = url;

  if (strncmp(p, "https://", 8) == 0)
    {
      *https = true;
      *port = HTTPS_PORT;
      p += 8;
    }
  else if (strncmp(p, "http://", 7) == 0)
    {
      *https = false;
      *port = HTTP_PORT;
      p += 7;
    }
  else
    {
      return -EINVAL;
    }

  const char *host_start = p;
  const char *slash = strchr(p, '/');
  const char *colon = strchr(p, ':');

  if (colon && (!slash || colon < slash))
    {
      int host_len = colon - host_start;
      if (host_len >= HTTP_MAX_HOST)
        {
          host_len = HTTP_MAX_HOST - 1;
        }

      memcpy(host, host_start, host_len);
      host[host_len] = '\0';
      *port = atoi(colon + 1);
    }
  else
    {
      int host_len = slash ? (slash - host_start) : (int)strlen(host_start);
      if (host_len >= HTTP_MAX_HOST)
        {
          host_len = HTTP_MAX_HOST - 1;
        }

      memcpy(host, host_start, host_len);
      host[host_len] = '\0';
    }

  if (slash)
    {
      strncpy(path, slash, HTTP_MAX_URL - 1);
      path[HTTP_MAX_URL - 1] = '\0';
    }
  else
    {
      strcpy(path, "/");
    }

  return 0;
}

/**
 * Connect to the server. Returns socket fd or negative error.
 */

static int connect_to_server(const char *host, int port)
{
  struct sockaddr_in addr;
  struct hostent *he;
  int fd;
  int ret;

  he = gethostbyname(host);
  if (!he)
    {
      return -EHOSTUNREACH;
    }

  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0)
    {
      return -errno;
    }

  struct timeval tv;
  tv.tv_sec = HTTP_TIMEOUT_SEC;
  tv.tv_usec = 0;
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
  setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  memcpy(&addr.sin_addr, he->h_addr, he->h_length);

  ret = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
  if (ret < 0)
    {
      close(fd);
      return -errno;
    }

  return fd;
}

/**
 * Send full buffer over socket.
 */

static int send_all(int fd, const char *buf, int len)
{
  int sent = 0;
  while (sent < len)
    {
      int n = send(fd, buf + sent, len - sent, 0);
      if (n <= 0)
        {
          return n < 0 ? -errno : -EPIPE;
        }

      sent += n;
    }

  return 0;
}

/**
 * Receive response from socket into buffer.
 */

static int recv_response(int fd, char *buf, int max_len)
{
  int total = 0;
  int n;

  while (total < max_len - 1)
    {
      n = recv(fd, buf + total, max_len - 1 - total, 0);
      if (n < 0)
        {
          if (total > 0)
            {
              break;
            }

          return -errno;
        }

      if (n == 0)
        {
          break;
        }

      total += n;

      buf[total] = '\0';
      if (strstr(buf, "\r\n\r\n"))
        {
          char *cl = strstr(buf, "Content-Length:");
          if (!cl)
            {
              cl = strstr(buf, "content-length:");
            }

          if (cl)
            {
              int content_len = atoi(cl + 15);
              char *body_start = strstr(buf, "\r\n\r\n");
              if (body_start)
                {
                  int body_received = total - (body_start + 4 - buf);
                  if (body_received >= content_len)
                    {
                      break;
                    }
                }
            }
          else
            {
              continue;
            }
        }
    }

  buf[total] = '\0';
  return total;
}

/**
 * Parse HTTP response to extract status code and body.
 */

static int parse_response(const char *raw, http_response_t *resp)
{
  if (strncmp(raw, "HTTP/", 5) != 0)
    {
      return -EBADMSG;
    }

  const char *status_start = strchr(raw, ' ');
  if (!status_start)
    {
      return -EBADMSG;
    }

  resp->status_code = atoi(status_start + 1);

  const char *body = strstr(raw, "\r\n\r\n");
  if (body)
    {
      body += 4;
      int body_len = strlen(body);
      if (body_len >= HTTP_MAX_RESPONSE)
        {
          body_len = HTTP_MAX_RESPONSE - 1;
        }

      memcpy(resp->body, body, body_len);
      resp->body[body_len] = '\0';
      resp->body_len = body_len;
    }
  else
    {
      resp->body[0] = '\0';
      resp->body_len = 0;
    }

  return 0;
}

/**
 * Perform a raw HTTP request.
 */

static int do_request(const char *method, const char *host, int port,
                      const char *path, const char *token,
                      const char *body, http_response_t *resp)
{
  char request[HTTP_MAX_REQUEST];
  char raw_resp[HTTP_MAX_RESPONSE + 512];
  int fd;
  int ret;
  int offset;

  fd = connect_to_server(host, port);
  if (fd < 0)
    {
      return fd;
    }

  offset = snprintf(request, sizeof(request),
                    "%s %s HTTP/1.1\r\n"
                    "Host: %s\r\n"
                    "Connection: close\r\n"
                    "Content-Type: application/json; charset=utf-8\r\n",
                    method, path, host);

  if (token && token[0])
    {
      offset += snprintf(request + offset, sizeof(request) - offset,
                         "Authorization: Bearer %s\r\n", token);
    }

  if (body && body[0])
    {
      offset += snprintf(request + offset, sizeof(request) - offset,
                         "Content-Length: %d\r\n", (int)strlen(body));
    }
  else
    {
      offset += snprintf(request + offset, sizeof(request) - offset,
                         "Content-Length: 0\r\n");
    }

  offset += snprintf(request + offset, sizeof(request) - offset, "\r\n");

  if (body && body[0])
    {
      int body_len = strlen(body);
      if (offset + body_len < (int)sizeof(request))
        {
          memcpy(request + offset, body, body_len);
          offset += body_len;
        }
    }

  ret = send_all(fd, request, offset);
  if (ret < 0)
    {
      close(fd);
      return ret;
    }

  ret = recv_response(fd, raw_resp, sizeof(raw_resp));
  close(fd);

  if (ret < 0)
    {
      return ret;
    }

  return parse_response(raw_resp, resp);
}

#endif /* CONFIG_NET */

/****************************************************************************
 * Public Functions
 ****************************************************************************/

void http_client_init(void)
{
#ifdef CONFIG_NET
  char path[HTTP_MAX_URL];
  parse_url(CONFIG_EXAMPLES_ELDERLY_BES_SERVER_URL,
            g_server_host, &g_server_port, path, &g_use_https);
#else
  (void)g_server_host;
  (void)g_server_port;
  (void)g_use_https;
#endif
}

int http_get(const char *path, const char *token, http_response_t *resp)
{
#ifdef CONFIG_NET
  return do_request("GET", g_server_host, g_server_port,
                    path, token, NULL, resp);
#else
  (void)path;
  (void)token;
  (void)resp;
  return -ENOSYS;
#endif
}

int http_post(const char *path, const char *token,
              const char *json, http_response_t *resp)
{
#ifdef CONFIG_NET
  return do_request("POST", g_server_host, g_server_port,
                    path, token, json, resp);
#else
  (void)path;
  (void)token;
  (void)json;
  (void)resp;
  return -ENOSYS;
#endif
}

int http_upload_vitals(const char *device_sn, const char *json)
{
#ifdef CONFIG_NET
  char path[HTTP_MAX_URL];
  http_response_t resp;

  snprintf(path, sizeof(path), "/v1/devices/%s/vital", device_sn);
  return http_post(path, NULL, json, &resp);
#else
  (void)device_sn;
  (void)json;
  return -ENOSYS;
#endif
}

int http_upload_alarm(const char *device_sn, const char *json)
{
#ifdef CONFIG_NET
  char path[HTTP_MAX_URL];
  http_response_t resp;

  snprintf(path, sizeof(path), "/v1/devices/%s/alarm", device_sn);
  return http_post(path, NULL, json, &resp);
#else
  (void)device_sn;
  (void)json;
  return -ENOSYS;
#endif
}

int http_upload_heartbeat(const char *device_sn, const char *json)
{
#ifdef CONFIG_NET
  char path[HTTP_MAX_URL];
  http_response_t resp;

  snprintf(path, sizeof(path), "/v1/devices/%s/heartbeat", device_sn);
  return http_post(path, NULL, json, &resp);
#else
  (void)device_sn;
  (void)json;
  return -ENOSYS;
#endif
}

int http_upload_position(const char *device_sn, const char *json)
{
#ifdef CONFIG_NET
  char path[HTTP_MAX_URL];
  http_response_t resp;

  snprintf(path, sizeof(path), "/v1/devices/%s/position", device_sn);
  return http_post(path, NULL, json, &resp);
#else
  (void)device_sn;
  (void)json;
  return -ENOSYS;
#endif
}
