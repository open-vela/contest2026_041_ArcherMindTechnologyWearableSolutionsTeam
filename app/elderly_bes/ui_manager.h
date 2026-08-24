/****************************************************************************
 * apps/examples/elderly/ui_manager.h
 *
 * Page manager: handles page creation, switching, and lifecycle.
 ****************************************************************************/

#ifndef __UI_MANAGER_H
#define __UI_MANAGER_H

#include "ui_common.h"

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * Initialize the UI manager and create all pages.
 * Call after LVGL is initialized.
 */

void ui_manager_init(void);

/**
 * Switch to a specific page with optional animation.
 */

void ui_manager_switch_page(page_id_t page);

/**
 * Get the LVGL screen object for a specific page.
 */

lv_obj_t *ui_manager_get_page(page_id_t page);

/**
 * Refresh the current page data (called by data collector).
 */

void ui_manager_refresh(void);

/**
 * Get the page container object (for overlay elements like SOS popup).
 */

lv_obj_t *ui_manager_get_layer(void);

#endif /* __UI_MANAGER_H */
