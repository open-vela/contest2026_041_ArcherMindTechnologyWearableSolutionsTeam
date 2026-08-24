/****************************************************************************
 * apps/examples/elderly/ui_settings.h
 *
 * Settings page: brightness, collection interval, toggles, upload mode.
 ****************************************************************************/

#ifndef __UI_SETTINGS_H
#define __UI_SETTINGS_H

#include "ui_common.h"

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * Create the settings page on the given parent object.
 */

lv_obj_t *ui_settings_create(lv_obj_t *parent);

/**
 * Apply current settings to UI controls (called when entering page).
 */

void ui_settings_sync_controls(void);

#endif /* __UI_SETTINGS_H */
