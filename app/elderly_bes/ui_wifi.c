/****************************************************************************
 * apps/examples/elderly_bes/ui_wifi.c
 *
 * WiFi 设置页面：扫描网络、选择、输入密码、连接。
 * 适配 454×454 圆形显示屏。
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "ui_wifi.h"
#include "ui_manager.h"
#include "wifi_manager.h"

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

#define WIFI_LIST_VISIBLE   3       /* 列表可见项数 */
#define WIFI_ITEM_H         48      /* 列表项高度 */
#define PASS_MAX_LEN        63

/****************************************************************************
 * Private Data
 ****************************************************************************/

/* 主页面控件 */

static lv_obj_t *g_wifi_status_label;
static lv_obj_t *g_wifi_ssid_label;
static lv_obj_t *g_wifi_ip_label;
static lv_obj_t *g_scan_btn_label;
static lv_obj_t *g_wifi_list;

/* 密码输入对话框 */

static lv_obj_t *g_pass_dialog;
static lv_obj_t *g_pass_ta;         /* 密码输入框 */
static lv_obj_t *g_pass_kb;         /* 软键盘 */
static lv_obj_t *g_pass_title;
static char g_selected_ssid[WIFI_MAX_SSID_LEN];

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/**
 * 返回按钮事件
 */

static void back_btn_cb(lv_event_t *e)
{
  LV_UNUSED(e);
  ui_manager_switch_page(PAGE_SETTINGS);
}

/**
 * 更新状态显示
 */

static void update_status_display(void)
{
  wifi_status_t st = wifi_manager_get_status();
  const char *ssid = wifi_manager_get_ssid();
  const char *ip = wifi_manager_get_ip();
  const char *st_str = wifi_manager_get_status_str();

  lv_label_set_text(g_wifi_status_label, st_str);

  if (st == WIFI_STATUS_CONNECTED)
    {
      lv_obj_set_style_text_color(g_wifi_status_label, COLOR_GREEN, 0);
      lv_label_set_text(g_wifi_ssid_label, ssid);
      char ip_buf[48];
      snprintf(ip_buf, sizeof(ip_buf), "IP: %s", ip);
      lv_label_set_text(g_wifi_ip_label, ip_buf);
    }
  else if (st == WIFI_STATUS_CONNECTING)
    {
      lv_obj_set_style_text_color(g_wifi_status_label, COLOR_YELLOW, 0);
      lv_label_set_text(g_wifi_ssid_label, ssid);
      lv_label_set_text(g_wifi_ip_label, "IP: --");
    }
  else
    {
      lv_obj_set_style_text_color(g_wifi_status_label, COLOR_TEXT_DIM, 0);
      lv_label_set_text(g_wifi_ssid_label, "Not connected");
      lv_label_set_text(g_wifi_ip_label, "");
    }
}

/**
 * 重建扫描结果列表
 */

static void rebuild_scan_list(void)
{
  lv_obj_clean(g_wifi_list);

  int count = wifi_manager_get_scan_count();
  if (count == 0)
    {
      lv_obj_t *empty = lv_label_create(g_wifi_list);
      lv_label_set_text(empty, "No networks found");
      lv_obj_set_style_text_color(empty, COLOR_TEXT_DIM, 0);
      lv_obj_set_style_text_font(empty, &lv_font_montserrat_14, 0);
      lv_obj_center(empty);
      return;
    }

  for (int i = 0; i < count; i++)
    {
      wifi_ap_info_t ap;
      if (wifi_manager_get_ap(i, &ap) != 0)
        continue;

      lv_obj_t *item = lv_obj_create(g_wifi_list);
      lv_obj_set_size(item, CONTENT_WIDTH, WIFI_ITEM_H);
      lv_obj_set_style_bg_color(item, COLOR_CARD_BG, 0);
      lv_obj_set_style_bg_opa(item, LV_OPA_COVER, 0);
      lv_obj_set_style_radius(item, 10, 0);
      lv_obj_set_style_border_width(item, 0, 0);
      lv_obj_set_style_pad_hor(item, 10, 0);
      lv_obj_remove_flag(item, LV_OBJ_FLAG_SCROLLABLE);
      lv_obj_add_flag(item, LV_OBJ_FLAG_CLICKABLE);

      /* SSID */

      lv_obj_t *ssid_lbl = lv_label_create(item);
      lv_label_set_text(ssid_lbl, ap.ssid);
      lv_obj_set_style_text_color(ssid_lbl, COLOR_TEXT_PRIMARY, 0);
      lv_obj_set_style_text_font(ssid_lbl, &lv_font_montserrat_16, 0);
      lv_obj_align(ssid_lbl, LV_ALIGN_LEFT_MID, 0, -4);

      /* 信号强度 + 加密图标 */

      char info_buf[32];
      const char *lock = ap.encrypt > 0 ? LV_SYMBOL_CLOSE : "";
      snprintf(info_buf, sizeof(info_buf), "%s %ddBm", lock, ap.rssi);

      lv_obj_t *info_lbl = lv_label_create(item);
      lv_label_set_text(info_lbl, info_buf);
      lv_obj_set_style_text_color(info_lbl, COLOR_TEXT_SECONDARY, 0);
      lv_obj_set_style_text_font(info_lbl, &lv_font_montserrat_14, 0);
      lv_obj_align(info_lbl, LV_ALIGN_RIGHT_MID, 0, -4);

      /* 信号强度条 */

      int bars = 0;
      if (ap.rssi > -50) bars = 4;
      else if (ap.rssi > -60) bars = 3;
      else if (ap.rssi > -70) bars = 2;
      else bars = 1;

      lv_obj_t *sig = lv_obj_create(item);
      lv_obj_set_size(sig, bars * 4 + 2, 12);
      lv_obj_align(sig, LV_ALIGN_RIGHT_MID, 0, 10);
      lv_obj_set_style_bg_color(sig, COLOR_GREEN, 0);
      lv_obj_set_style_radius(sig, 2, 0);
      lv_obj_set_style_border_width(sig, 0, 0);

      /* 点击事件 — 选择此网络 */

      lv_obj_add_event_cb(item, NULL, LV_EVENT_CLICKED, NULL);
    }
}

/**
 * 密码输入对话框 — 键盘事件
 */

static void kb_event_cb(lv_event_t *e)
{
  lv_keyboard_t *kb = (lv_keyboard_t *)lv_event_get_target(e);
  LV_UNUSED(kb);
}

/**
 * 密码输入对话框 — 连接按钮
 */

static void connect_btn_cb(lv_event_t *e)
{
  LV_UNUSED(e);
  const char *pass = lv_textarea_get_text(g_pass_ta);

  LV_LOG_USER("[WIFI] Connecting to '%s'...", g_selected_ssid);

  wifi_manager_connect(g_selected_ssid, pass);

  /* 关闭对话框 */

  lv_obj_add_flag(g_pass_dialog, LV_OBJ_FLAG_HIDDEN);
  lv_obj_del(g_pass_dialog);
  g_pass_dialog = NULL;

  /* 刷新状态 */

  update_status_display();
}

/**
 * 密码输入对话框 — 取消按钮
 */

static void cancel_btn_cb(lv_event_t *e)
{
  LV_UNUSED(e);
  if (g_pass_dialog)
    {
      lv_obj_add_flag(g_pass_dialog, LV_OBJ_FLAG_HIDDEN);
      lv_obj_del(g_pass_dialog);
      g_pass_dialog = NULL;
    }
}

/**
 * 密码输入对话框 — 显示/隐藏密码
 */

static void show_pass_cb(lv_event_t *e)
{
  LV_UNUSED(e);
  if (g_pass_ta)
    {
      bool hidden = lv_textarea_get_password_mode(g_pass_ta);
      lv_textarea_set_password_mode(g_pass_ta, !hidden);
    }
}

/**
 * 创建密码输入对话框
 */

static void create_password_dialog(const char *ssid)
{
  /* 如果已有对话框，先删除 */

  if (g_pass_dialog)
    {
      lv_obj_del(g_pass_dialog);
      g_pass_dialog = NULL;
    }

  strncpy(g_selected_ssid, ssid, WIFI_MAX_SSID_LEN - 1);
  g_selected_ssid[WIFI_MAX_SSID_LEN - 1] = '\0';

  /* 创建全屏遮罩 */

  g_pass_dialog = lv_obj_create(lv_screen_active());
  lv_obj_set_size(g_pass_dialog, SCREEN_WIDTH, SCREEN_HEIGHT);
  lv_obj_set_style_bg_color(g_pass_dialog, lv_color_hex(0x000000), 0);
  lv_obj_set_style_bg_opa(g_pass_dialog, LV_OPA_90, 0);
  lv_obj_set_style_border_width(g_pass_dialog, 0, 0);
  lv_obj_set_style_pad_all(g_pass_dialog, 0, 0);
  lv_obj_remove_flag(g_pass_dialog, LV_OBJ_FLAG_SCROLLABLE);

  /* 标题 */

  g_pass_title = lv_label_create(g_pass_dialog);
  char title_buf[64];
  snprintf(title_buf, sizeof(title_buf), "Connect to:\n%s", ssid);
  lv_label_set_text(g_pass_title, title_buf);
  lv_obj_set_style_text_color(g_pass_title, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_pass_title, &lv_font_montserrat_20, 0);
  lv_obj_set_style_text_align(g_pass_title, LV_TEXT_ALIGN_CENTER, 0);
  lv_obj_align(g_pass_title, LV_ALIGN_TOP_MID, 0, SAFE_MARGIN + 5);

  /* 密码输入框 */

  g_pass_ta = lv_textarea_create(g_pass_dialog);
  lv_obj_set_size(g_pass_ta, CONTENT_WIDTH - 20, 40);
  lv_obj_align(g_pass_ta, LV_ALIGN_TOP_MID, 0, SAFE_MARGIN + 60);
  lv_textarea_set_placeholder_text(g_pass_ta, "Enter password");
  lv_textarea_set_password_mode(g_pass_ta, true);
  lv_textarea_set_one_line(g_pass_ta, true);
  lv_textarea_set_max_length(g_pass_ta, PASS_MAX_LEN);
  lv_obj_set_style_text_font(g_pass_ta, &lv_font_montserrat_16, 0);

  /* 显示/隐藏密码按钮 */

  lv_obj_t *show_btn = lv_button_create(g_pass_dialog);
  lv_obj_set_size(show_btn, 40, 36);
  lv_obj_align(show_btn, LV_ALIGN_TOP_MID, 130, SAFE_MARGIN + 62);
  lv_obj_set_style_radius(show_btn, 8, 0);
  lv_obj_set_style_bg_color(show_btn, COLOR_CARD_BG2, 0);
  lv_obj_t *eye_lbl = lv_label_create(show_btn);
  lv_label_set_text(eye_lbl, LV_SYMBOL_EYE_OPEN);
  lv_obj_center(eye_lbl);
  lv_obj_add_event_cb(show_btn, show_pass_cb, LV_EVENT_CLICKED, NULL);

  /* 连接按钮 */

  lv_obj_t *connect_btn = lv_button_create(g_pass_dialog);
  lv_obj_set_size(connect_btn, CONTENT_WIDTH / 2 - 8, 40);
  lv_obj_align(connect_btn, LV_ALIGN_TOP_MID,
               -(CONTENT_WIDTH / 4 + 4), SAFE_MARGIN + 110);
  lv_obj_set_style_radius(connect_btn, 20, 0);
  lv_obj_set_style_bg_color(connect_btn, COLOR_BLUE, 0);
  lv_obj_t *conn_lbl = lv_label_create(connect_btn);
  lv_label_set_text(conn_lbl, LV_SYMBOL_OK " Connect");
  lv_obj_set_style_text_color(conn_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(conn_lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(conn_lbl);
  lv_obj_add_event_cb(connect_btn, connect_btn_cb, LV_EVENT_CLICKED, NULL);

  /* 取消按钮 */

  lv_obj_t *cancel_btn = lv_button_create(g_pass_dialog);
  lv_obj_set_size(cancel_btn, CONTENT_WIDTH / 2 - 8, 40);
  lv_obj_align(cancel_btn, LV_ALIGN_TOP_MID,
               (CONTENT_WIDTH / 4 + 4), SAFE_MARGIN + 110);
  lv_obj_set_style_radius(cancel_btn, 20, 0);
  lv_obj_set_style_bg_color(cancel_btn, COLOR_CARD_BG2, 0);
  lv_obj_t *canc_lbl = lv_label_create(cancel_btn);
  lv_label_set_text(canc_lbl, LV_SYMBOL_CLOSE " Cancel");
  lv_obj_set_style_text_color(canc_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(canc_lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(canc_lbl);
  lv_obj_add_event_cb(cancel_btn, cancel_btn_cb, LV_EVENT_CLICKED, NULL);

  /* 软键盘 */

  g_pass_kb = lv_keyboard_create(g_pass_dialog);
  lv_obj_set_size(g_pass_kb, SCREEN_WIDTH - 20,
                  SCREEN_HEIGHT - SAFE_MARGIN - 170);
  lv_obj_align(g_pass_kb, LV_ALIGN_BOTTOM_MID, 0, -10);
  lv_keyboard_set_textarea(g_pass_kb, g_pass_ta);
  lv_obj_set_style_text_font(g_pass_kb, &lv_font_montserrat_14, 0);
}

/**
 * 扫描按钮事件
 */

static void scan_btn_cb(lv_event_t *e)
{
  LV_UNUSED(e);
  lv_label_set_text(g_scan_btn_label, LV_SYMBOL_REFRESH " Scanning...");
  lv_obj_invalidate(lv_obj_get_parent(g_scan_btn_label));

  /* 执行扫描 */

  int count = wifi_manager_scan();

  char buf[32];
  snprintf(buf, sizeof(buf), LV_SYMBOL_REFRESH " Scan (%d)", count);
  lv_label_set_text(g_scan_btn_label, buf);

  /* 刷新列表 */

  rebuild_scan_list();
}

/**
 * 网络列表项点击事件代理
 */

static void list_click_cb(lv_event_t *e)
{
  int idx = (int)(intptr_t)lv_event_get_user_data(e);

  wifi_ap_info_t ap;
  if (wifi_manager_get_ap(idx, &ap) != 0)
    return;

  /* 已知网络 (RD2/RD2_5G) 直接连接，跳过密码输入 */

  if (strcmp(ap.ssid, "RD2") == 0 || strcmp(ap.ssid, "RD2_5G") == 0)
    {
      LV_LOG_USER("[WIFI] Known network '%s', connecting directly", ap.ssid);
      wifi_manager_connect(ap.ssid, "");  /* 密码由 wifi_manager 自动填充 */
      update_status_display();
      return;
    }

  if (ap.encrypt > 0)
    {
      /* 加密网络 — 弹出密码输入 */

      create_password_dialog(ap.ssid);
    }
  else
    {
      /* 开放网络 — 直接连接 */

      wifi_manager_connect(ap.ssid, "");
      update_status_display();
    }
}

/**
 * 重建扫描结果列表（带点击事件）
 */

static void rebuild_scan_list_with_events(void)
{
  lv_obj_clean(g_wifi_list);

  int count = wifi_manager_get_scan_count();
  if (count == 0)
    {
      lv_obj_t *empty = lv_label_create(g_wifi_list);
      lv_label_set_text(empty, "No networks");
      lv_obj_set_style_text_color(empty, COLOR_TEXT_DIM, 0);
      lv_obj_set_style_text_font(empty, &lv_font_montserrat_14, 0);
      lv_obj_center(empty);
      return;
    }

  for (int i = 0; i < count; i++)
    {
      wifi_ap_info_t ap;
      if (wifi_manager_get_ap(i, &ap) != 0)
        continue;

      lv_obj_t *item = lv_obj_create(g_wifi_list);
      lv_obj_set_size(item, CONTENT_WIDTH, WIFI_ITEM_H);
      lv_obj_set_style_bg_color(item, COLOR_CARD_BG, 0);
      lv_obj_set_style_bg_opa(item, LV_OPA_COVER, 0);
      lv_obj_set_style_radius(item, 10, 0);
      lv_obj_set_style_border_width(item, 0, 0);
      lv_obj_set_style_pad_hor(item, 10, 0);
      lv_obj_remove_flag(item, LV_OBJ_FLAG_SCROLLABLE);
      lv_obj_add_flag(item, LV_OBJ_FLAG_CLICKABLE);

      /* SSID */

      lv_obj_t *ssid_lbl = lv_label_create(item);
      lv_label_set_text(ssid_lbl, ap.ssid);
      lv_obj_set_style_text_color(ssid_lbl, COLOR_TEXT_PRIMARY, 0);
      lv_obj_set_style_text_font(ssid_lbl, &lv_font_montserrat_16, 0);
      lv_obj_align(ssid_lbl, LV_ALIGN_LEFT_MID, 0, -4);

      /* 信号强度 + 加密图标 */

      char info_buf[32];
      const char *lock = ap.encrypt > 0 ? LV_SYMBOL_CLOSE : "";
      snprintf(info_buf, sizeof(info_buf), "%s %ddBm", lock, ap.rssi);

      lv_obj_t *info_lbl = lv_label_create(item);
      lv_label_set_text(info_lbl, info_buf);
      lv_obj_set_style_text_color(info_lbl, COLOR_TEXT_SECONDARY, 0);
      lv_obj_set_style_text_font(info_lbl, &lv_font_montserrat_14, 0);
      lv_obj_align(info_lbl, LV_ALIGN_RIGHT_MID, 0, -4);

      /* 点击事件 */

      lv_obj_add_event_cb(item, list_click_cb, LV_EVENT_CLICKED,
                           (void *)(intptr_t)i);
    }
}

/**
 * 扫描按钮事件（带点击事件版本）
 */

static void scan_btn_cb_v2(lv_event_t *e)
{
  LV_UNUSED(e);
  lv_label_set_text(g_scan_btn_label, LV_SYMBOL_REFRESH " Scanning...");

  int count = wifi_manager_scan();

  char buf[32];
  snprintf(buf, sizeof(buf), LV_SYMBOL_REFRESH " Scan (%d)", count);
  lv_label_set_text(g_scan_btn_label, buf);

  rebuild_scan_list_with_events();
}

/**
 * 断开按钮事件
 */

static void disconnect_btn_cb(lv_event_t *e)
{
  LV_UNUSED(e);
  wifi_manager_disconnect();
  update_status_display();
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

lv_obj_t *ui_wifi_create(lv_obj_t *parent)
{
  wifi_manager_init();

  lv_obj_t *page = lv_obj_create(parent);
  lv_obj_set_size(page, SCREEN_WIDTH, SCREEN_HEIGHT);
  lv_obj_set_style_bg_opa(page, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(page, 0, 0);
  lv_obj_set_style_pad_all(page, 0, 0);
  lv_obj_remove_flag(page, LV_OBJ_FLAG_SCROLLABLE);

  int top_y = SAFE_MARGIN + 5;

  /* 标题 + 返回按钮 */

  lv_obj_t *back_btn = lv_button_create(page);
  lv_obj_set_size(back_btn, 36, 36);
  lv_obj_align(back_btn, LV_ALIGN_TOP_LEFT, SAFE_MARGIN, top_y);
  lv_obj_set_style_radius(back_btn, 18, 0);
  lv_obj_set_style_bg_color(back_btn, COLOR_CARD_BG2, 0);
  lv_obj_t *back_lbl = lv_label_create(back_btn);
  lv_label_set_text(back_lbl, LV_SYMBOL_LEFT);
  lv_obj_set_style_text_color(back_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_center(back_lbl);
  lv_obj_add_event_cb(back_btn, back_btn_cb, LV_EVENT_CLICKED, NULL);

  lv_obj_t *title = lv_label_create(page);
  lv_label_set_text(title, LV_SYMBOL_WIFI " WiFi");
  lv_obj_set_style_text_color(title, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(title, &lv_font_montserrat_20, 0);
  lv_obj_align(title, LV_ALIGN_TOP_MID, 0, top_y + 3);

  /* 状态卡片 */

  lv_obj_t *status_card = lv_obj_create(page);
  lv_obj_set_size(status_card, CONTENT_WIDTH, 60);
  lv_obj_align(status_card, LV_ALIGN_TOP_MID, 0, top_y + 32);
  lv_obj_set_style_bg_color(status_card, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(status_card, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(status_card, 12, 0);
  lv_obj_set_style_border_width(status_card, 0, 0);
  lv_obj_set_style_pad_all(status_card, 8, 0);
  lv_obj_remove_flag(status_card, LV_OBJ_FLAG_SCROLLABLE);

  g_wifi_status_label = lv_label_create(status_card);
  lv_label_set_text(g_wifi_status_label, "Disconnected");
  lv_obj_set_style_text_color(g_wifi_status_label, COLOR_TEXT_DIM, 0);
  lv_obj_set_style_text_font(g_wifi_status_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_wifi_status_label, LV_ALIGN_TOP_LEFT, 0, 0);

  g_wifi_ssid_label = lv_label_create(status_card);
  lv_label_set_text(g_wifi_ssid_label, "Not connected");
  lv_obj_set_style_text_color(g_wifi_ssid_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_wifi_ssid_label, &lv_font_montserrat_16, 0);
  lv_obj_align(g_wifi_ssid_label, LV_ALIGN_BOTTOM_LEFT, 0, 0);

  g_wifi_ip_label = lv_label_create(status_card);
  lv_label_set_text(g_wifi_ip_label, "");
  lv_obj_set_style_text_color(g_wifi_ip_label, COLOR_TEXT_SECONDARY, 0);
  lv_obj_set_style_text_font(g_wifi_ip_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_wifi_ip_label, LV_ALIGN_BOTTOM_RIGHT, 0, 0);

  /* 按钮行: Scan + Disconnect */

  int btn_w = (CONTENT_WIDTH - 8) / 2;

  lv_obj_t *scan_btn = lv_button_create(page);
  lv_obj_set_size(scan_btn, btn_w, 36);
  lv_obj_align(scan_btn, LV_ALIGN_TOP_MID, -(btn_w / 2 + 4), top_y + 100);
  lv_obj_set_style_radius(scan_btn, 18, 0);
  lv_obj_set_style_bg_color(scan_btn, COLOR_BLUE, 0);
  g_scan_btn_label = lv_label_create(scan_btn);
  lv_label_set_text(g_scan_btn_label, LV_SYMBOL_REFRESH " Scan");
  lv_obj_set_style_text_color(g_scan_btn_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_scan_btn_label, &lv_font_montserrat_14, 0);
  lv_obj_center(g_scan_btn_label);
  lv_obj_add_event_cb(scan_btn, scan_btn_cb_v2, LV_EVENT_CLICKED, NULL);

  lv_obj_t *disc_btn = lv_button_create(page);
  lv_obj_set_size(disc_btn, btn_w, 36);
  lv_obj_align(disc_btn, LV_ALIGN_TOP_MID, (btn_w / 2 + 4), top_y + 100);
  lv_obj_set_style_radius(disc_btn, 18, 0);
  lv_obj_set_style_bg_color(disc_btn, COLOR_CARD_BG2, 0);
  lv_obj_t *disc_lbl = lv_label_create(disc_btn);
  lv_label_set_text(disc_lbl, LV_SYMBOL_CLOSE " Disconnect");
  lv_obj_set_style_text_color(disc_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(disc_lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(disc_lbl);
  lv_obj_add_event_cb(disc_btn, disconnect_btn_cb, LV_EVENT_CLICKED, NULL);

  /* 网络列表 */

  int list_h = SCREEN_HEIGHT - top_y - 150 - SAFE_MARGIN;
  if (list_h < 120) list_h = 120;

  g_wifi_list = lv_obj_create(page);
  lv_obj_set_size(g_wifi_list, CONTENT_WIDTH, list_h);
  lv_obj_align(g_wifi_list, LV_ALIGN_TOP_MID, 0, top_y + 145);
  lv_obj_set_style_bg_opa(g_wifi_list, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(g_wifi_list, 0, 0);
  lv_obj_set_style_pad_all(g_wifi_list, 0, 0);
  lv_obj_set_style_pad_row(g_wifi_list, 4, 0);
  lv_obj_set_flex_flow(g_wifi_list, LV_FLEX_FLOW_COLUMN);
  lv_obj_set_scroll_dir(g_wifi_list, LV_DIR_VER);
  lv_obj_add_flag(g_wifi_list, LV_OBJ_FLAG_SCROLLABLE);

  /* 初始提示 */

  lv_obj_t *hint = lv_label_create(g_wifi_list);
  lv_label_set_text(hint, "Tap Scan to find networks");
  lv_obj_set_style_text_color(hint, COLOR_TEXT_DIM, 0);
  lv_obj_set_style_text_font(hint, &lv_font_montserrat_14, 0);
  lv_obj_center(hint);

  /* 初始化 WiFi 状态 */

  update_status_display();

  return page;
}

void ui_wifi_refresh(void)
{
  update_status_display();
}
