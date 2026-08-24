/****************************************************************************
 * apps/examples/elderly/http_client.h
 *
 * HTTP client module for communicating with the backend API.
 * Supports GET/POST with JSON payloads via POSIX sockets.
 ****************************************************************************/

#ifndef __HTTP_CLIENT_H
#define __HTTP_CLIENT_H

#include <stdint.h>
#include <stdbool.h>

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

#define HTTP_MAX_RESPONSE   4096
#define HTTP_MAX_URL        256
#define HTTP_MAX_HEADER     512
#define HTTP_RECV_TIMEOUT   10   /* seconds */

/****************************************************************************
 * Public Type Definitions
 ****************************************************************************/

typedef struct
{
  int  status_code;
  char body[HTTP_MAX_RESPONSE];
  int  body_len;
} http_response_t;

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * Initialize the HTTP client module.
 */

void http_client_init(void);

/**
 * Perform an HTTP GET request.
 * @param path     API path (e.g., "/api/v1/vitals/xxx/realtime")
 * @param token    Authorization token (can be NULL)
 * @param resp     Response structure to fill
 * @return 0 on success, negative on error
 */

int http_get(const char *path, const char *token,
             http_response_t *resp);

/**
 * Perform an HTTP POST request with JSON body.
 * @param path     API path
 * @param token    Authorization token (can be NULL)
 * @param json     JSON body string
 * @param resp     Response structure to fill
 * @return 0 on success, negative on error
 */

int http_post(const char *path, const char *token,
              const char *json, http_response_t *resp);

/**
 * Upload vital sign data to the server.
 */

int http_upload_vitals(const char *device_sn, const char *json);

/**
 * Upload alarm event to the server.
 */

int http_upload_alarm(const char *device_sn, const char *json);

/**
 * Upload heartbeat to the server.
 */

int http_upload_heartbeat(const char *device_sn, const char *json);

/**
 * Upload position data to the server.
 */

int http_upload_position(const char *device_sn, const char *json);

#endif /* __HTTP_CLIENT_H */
