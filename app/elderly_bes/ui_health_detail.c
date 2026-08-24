/****************************************************************************
 * apps/examples/elderly/ui_health_detail.c
 *
 * Health detail page: heart rate detail with time range selector
 * and historical data list. Adapted for 454x454 circular display.
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "ui_health_detail.h"
#include "ui_manager.h"

/****************************************************************************
 * Private Data
 ****************************************************************************/

static lv_obj_t *g_hr_value_label;
static lv_obj_t *g_hr_status_label;
static lv_obj_t *g_hr_status_dot;
static lv_obj_t *g_list_cont;

static lv_obj_t *g_btn_1h;
static lv_obj_t *g_btn_6h;
static lv_obj_t *g_btn_24h;
static int32_t  g_selected_range = 1;  /* 1=1h, 6=6h, 24=24h */

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/**
 * Highlight the selected time range button.
 */

static void update_range_buttons(void)
{
  lv_color_t selected_border = COLOR_BLUE;
  lv_color_t unselected_border = COLOR_BORDER;
  lv_opa_t selected_opa = LV_OPA_COVER;
  lv_opa_t unselected_opa = LV_OPA_40;

  lv_obj_set_style_border_color(g_btn_1h,
    g_selected_range == 1 ? selected_border : unselected_border, 0);
  lv_obj_set_style_border_opa(g_btn_1h,
    g_selected_range == 1 ? selected_opa : unselected_opa, 0);
  lv_obj_set_style_text_color(g_btn_1h,
    g_selected_range == 1 ? COLOR_TEXT_PRIMARY : COLOR_TEXT_DIM, 0);

  lv_obj_set_style_border_color(g_btn_6h,
    g_selected_range == 6 ? selected_border : unselected_border, 0);
  lv_obj_set_style_border_opa(g_btn_6h,
    g_selected_range == 6 ? selected_opa : unselected_opa, 0);
  lv_obj_set_style_text_color(g_btn_6h,
    g_selected_range == 6 ? COLOR_TEXT_PRIMARY : COLOR_TEXT_DIM, 0);

  lv_obj_set_style_border_color(g_btn_24h,
    g_selected_range == 24 ? selected_border : unselected_border, 0);
  lv_obj_set_style_border_opa(g_btn_24h,
    g_selected_range == 24 ? selected_opa : unselected_opa, 0);
  lv_obj_set_style_text_color(g_btn_24h,
    g_selected_range == 24 ? COLOR_TEXT_PRIMARY : COLOR_TEXT_DIM, 0);
}

/**
 * Time range button event handler.
 */

static void range_btn_cb(lv_event_t *e)
{
  int32_t range = (int32_t)(intptr_t)lv_event_get_user_data(e);
  g_selected_range = range;
  update_range_buttons();
  ui_health_detail_update();
}

/**
 * Create a time range selector button.
 */

static lv_obj_t *create_range_btn(lv_obj_t *parent, const char *text)
{
  lv_obj_t *btn = lv_button_create(parent);
  lv_obj_set_size(btn, 60, 30);
  lv_obj_set_style_radius(btn, 15, 0);
  lv_obj_set_style_bg_color(btn, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(btn, LV_OPA_COVER, 0);
  lv_obj_set_style_border_width(btn, 2, 0);
  lv_obj_set_style_border_color(btn, COLOR_BORDER, 0);

  lv_obj_t *lbl = lv_label_create(btn);
  lv_label_set_text(lbl, text);
  lv_obj_set_style_text_color(lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(lbl, &lv_font_montserrat_14, 0);
  lv_obj_center(lbl);

  return btn;
}

/**
 * Create the time range selector row.
 */

static lv_obj_t *create_range_selector(lv_obj_t *parent)
{
  lv_obj_t *cont = lv_obj_create(parent);
  lv_obj_set_size(cont, CONTENT_WIDTH, 36);
  lv_obj_set_style_bg_opa(cont, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(cont, 0, 0);
  lv_obj_set_style_pad_all(cont, 0, 0);
  lv_obj_set_flex_flow(cont, LV_FLEX_FLOW_ROW);
  lv_obj_set_flex_align(cont, LV_FLEX_ALIGN_CENTER,
                         LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);
  lv_obj_set_style_flex_main_place(cont, LV_FLEX_ALIGN_SPACE_EVENLY, 0);
  lv_obj_remove_flag(cont, LV_OBJ_FLAG_SCROLLABLE);

  g_btn_1h = create_range_btn(cont, "1h");
  g_btn_6h = create_range_btn(cont, "6h");
  g_btn_24h = create_range_btn(cont, "24h");

  lv_obj_add_event_cb(g_btn_1h, range_btn_cb, LV_EVENT_CLICKED,
                       (void *)(intptr_t)1);
  lv_obj_add_event_cb(g_btn_6h, range_btn_cb, LV_EVENT_CLICKED,
                       (void *)(intptr_t)6);
  lv_obj_add_event_cb(g_btn_24h, range_btn_cb, LV_EVENT_CLICKED,
                       (void *)(intptr_t)24);

  update_range_buttons();

  return cont;
}

/**
 * Create a history list entry.
 */

static lv_obj_t *create_history_entry(lv_obj_t *parent,
                                       const char *time_str,
                                       int32_t value)
{
  lv_obj_t *entry = lv_obj_create(parent);
  lv_obj_set_size(entry, CONTENT_WIDTH, 40);
  lv_obj_set_style_bg_color(entry, COLOR_CARD_BG, 0);
  lv_obj_set_style_bg_opa(entry, LV_OPA_COVER, 0);
  lv_obj_set_style_radius(entry, 8, 0);
  lv_obj_set_style_border_width(entry, 0, 0);
  lv_obj_set_style_pad_hor(entry, 12, 0);
  lv_obj_remove_flag(entry, LV_OBJ_FLAG_SCROLLABLE);

  /* Time label */

  lv_obj_t *time_lbl = lv_label_create(entry);
  lv_label_set_text(time_lbl, time_str);
  lv_obj_set_style_text_color(time_lbl, COLOR_TEXT_SECONDARY, 0);
  lv_obj_set_style_text_font(time_lbl, &lv_font_montserrat_14, 0);
  lv_obj_align(time_lbl, LV_ALIGN_LEFT_MID, 0, 0);

  /* Heart rate value */

  char buf[16];
  snprintf(buf, sizeof(buf), "%ld bpm", (long)value);
  lv_obj_t *val_lbl = lv_label_create(entry);
  lv_label_set_text(val_lbl, buf);
  lv_obj_set_style_text_color(val_lbl, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(val_lbl, &lv_font_montserrat_14, 0);
  lv_obj_align(val_lbl, LV_ALIGN_RIGHT_MID, 0, 0);

  return entry;
}

/**
 * Rebuild the history list from current data.
 */

static void rebuild_history_list(void)
{
  /* Clear existing entries */

  lv_obj_clean(g_list_cont);

  app_context_t *ctx = app_get_context();
  int32_t count = ctx->hr_history_count;

  /* Limit display based on selected range */

  int32_t max_display;
  switch (g_selected_range)
    {
      case 1:
        max_display = 4;   /* ~15min intervals for 1h */
        break;
      case 6:
        max_display = 12;  /* ~30min intervals for 6h */
        break;
      case 24:
      default:
        max_display = 24;  /* ~1h intervals for 24h */
        break;
    }

  if (count > max_display)
    {
      count = max_display;
    }

  /* Create entries (show most recent first) */

  for (int32_t i = count - 1; i >= 0; i--)
    {
      create_history_entry(g_list_cont,
                           ctx->hr_history[i].time_str,
                           ctx->hr_history[i].value);
    }

  /* If no history, show placeholder */

  if (count == 0)
    {
      lv_obj_t *empty_lbl = lv_label_create(g_list_cont);
      lv_label_set_text(empty_lbl, "No data");
      lv_obj_set_style_text_color(empty_lbl, COLOR_TEXT_DIM, 0);
      lv_obj_set_style_text_font(empty_lbl, &lv_font_montserrat_14, 0);
      lv_obj_center(empty_lbl);
    }
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

lv_obj_t *ui_health_detail_create(lv_obj_t *parent)
{
  lv_obj_t *page = lv_obj_create(parent);
  lv_obj_set_size(page, SCREEN_WIDTH, SCREEN_HEIGHT);
  lv_obj_set_style_bg_opa(page, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(page, 0, 0);
  lv_obj_set_style_pad_all(page, 0, 0);
  lv_obj_remove_flag(page, LV_OBJ_FLAG_SCROLLABLE);

  int top_y = SAFE_MARGIN + 5;

  /* Title */

  lv_obj_t *title = lv_label_create(page);
  lv_label_set_text(title, "Heart Rate");
  lv_obj_set_style_text_color(title, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(title, &lv_font_montserrat_14, 0);
  lv_obj_align(title, LV_ALIGN_TOP_MID, 0, top_y);

  /* Main heart rate display */

  lv_obj_t *hr_cont = lv_obj_create(page);
  lv_obj_set_size(hr_cont, CONTENT_WIDTH, 60);
  lv_obj_align(hr_cont, LV_ALIGN_TOP_MID, 0, top_y + 30);
  lv_obj_set_style_bg_opa(hr_cont, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(hr_cont, 0, 0);
  lv_obj_set_style_pad_all(hr_cont, 0, 0);
  lv_obj_remove_flag(hr_cont, LV_OBJ_FLAG_SCROLLABLE);

  g_hr_value_label = lv_label_create(hr_cont);
  lv_label_set_text(g_hr_value_label, "72");
  lv_obj_set_style_text_color(g_hr_value_label, COLOR_TEXT_PRIMARY, 0);
  lv_obj_set_style_text_font(g_hr_value_label, &lv_font_montserrat_36, 0);
  lv_obj_align(g_hr_value_label, LV_ALIGN_LEFT_MID, 10, 0);

  lv_obj_t *bpm_lbl = lv_label_create(hr_cont);
  lv_label_set_text(bpm_lbl, "bpm");
  lv_obj_set_style_text_color(bpm_lbl, COLOR_TEXT_DIM, 0);
  lv_obj_set_style_text_font(bpm_lbl, &lv_font_montserrat_16, 0);
  lv_obj_align(bpm_lbl, LV_ALIGN_LEFT_MID, 80, 5);

  /* Status indicator */

  g_hr_status_dot = lv_obj_create(hr_cont);
  lv_obj_set_size(g_hr_status_dot, 10, 10);
  lv_obj_set_style_radius(g_hr_status_dot, 5, 0);
  lv_obj_set_style_bg_color(g_hr_status_dot, COLOR_GREEN, 0);
  lv_obj_set_style_border_width(g_hr_status_dot, 0, 0);
  lv_obj_align(g_hr_status_dot, LV_ALIGN_RIGHT_MID, -50, -5);

  g_hr_status_label = lv_label_create(hr_cont);
  lv_label_set_text(g_hr_status_label, "Normal");
  lv_obj_set_style_text_color(g_hr_status_label, COLOR_GREEN, 0);
  lv_obj_set_style_text_font(g_hr_status_label, &lv_font_montserrat_14, 0);
  lv_obj_align(g_hr_status_label, LV_ALIGN_RIGHT_MID, 0, -5);

  /* Separator line */

  lv_obj_t *sep = lv_obj_create(page);
  lv_obj_set_size(sep, CONTENT_WIDTH - 20, 1);
  lv_obj_align(sep, LV_ALIGN_TOP_MID, 0, top_y + 100);
  lv_obj_set_style_bg_color(sep, COLOR_BORDER, 0);
  lv_obj_set_style_bg_opa(sep, LV_OPA_COVER, 0);
  lv_obj_set_style_border_width(sep, 0, 0);

  /* Time range selector */

  lv_obj_t *range_sel = create_range_selector(page);
  lv_obj_align(range_sel, LV_ALIGN_TOP_MID, 0, top_y + 110);

  /* Scrollable history list */

  int list_h = SCREEN_HEIGHT - top_y - 160 - SAFE_MARGIN;
  if (list_h < 100)
    {
      list_h = 100;
    }

  g_list_cont = lv_obj_create(page);
  lv_obj_set_size(g_list_cont, CONTENT_WIDTH, list_h);
  lv_obj_align(g_list_cont, LV_ALIGN_TOP_MID, 0, top_y + 155);
  lv_obj_set_style_bg_opa(g_list_cont, LV_OPA_TRANSP, 0);
  lv_obj_set_style_border_width(g_list_cont, 0, 0);
  lv_obj_set_style_pad_all(g_list_cont, 0, 0);
  lv_obj_set_style_pad_row(g_list_cont, 4, 0);
  lv_obj_set_flex_flow(g_list_cont, LV_FLEX_FLOW_COLUMN);
  lv_obj_set_scroll_dir(g_list_cont, LV_DIR_VER);
  lv_obj_add_flag(g_list_cont, LV_OBJ_FLAG_SCROLLABLE);

  return page;
}

void ui_health_detail_update(void)
{
  app_context_t *ctx = app_get_context();
  char buf[16];

  /* Update main display */

  snprintf(buf, sizeof(buf), "%ld", (long)ctx->vitals.heart_rate);
  lv_label_set_text(g_hr_value_label, buf);

  /* Update status */

  const char *status = get_hr_status(ctx->vitals.heart_rate);
  lv_color_t color = get_hr_status_color(ctx->vitals.heart_rate);
  lv_label_set_text(g_hr_status_label, status);
  lv_obj_set_style_text_color(g_hr_status_label, color, 0);
  lv_obj_set_style_bg_color(g_hr_status_dot, color, 0);

  /* Rebuild history list */

  rebuild_history_list();
}
