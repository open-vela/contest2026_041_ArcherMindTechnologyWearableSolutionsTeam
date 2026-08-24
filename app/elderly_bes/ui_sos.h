/****************************************************************************
 * apps/examples/elderly/ui_sos.h
 *
 * SOS/Alarm page: countdown timer, vital signs, location, cancel button.
 ****************************************************************************/

#ifndef __UI_SOS_H
#define __UI_SOS_H

#include "ui_common.h"

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * Create the SOS alarm page on the given parent object.
 */

lv_obj_t *ui_sos_create(lv_obj_t *parent);

/**
 * Activate the SOS alarm with a countdown.
 */

void ui_sos_activate(const char *alarm_type);

/**
 * Cancel the active alarm.
 */

void ui_sos_cancel(void);

/**
 * Update the countdown display (called every second).
 */

void ui_sos_update_countdown(void);

/**
 * Check if alarm is currently active.
 */

bool ui_sos_is_active(void);

#endif /* __UI_SOS_H */
