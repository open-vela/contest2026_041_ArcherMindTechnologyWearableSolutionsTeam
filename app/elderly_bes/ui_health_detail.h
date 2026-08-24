/****************************************************************************
 * apps/examples/elderly/ui_health_detail.h
 *
 * Health detail page: heart rate detail with time range and history list.
 ****************************************************************************/

#ifndef __UI_HEALTH_DETAIL_H
#define __UI_HEALTH_DETAIL_H

#include "ui_common.h"

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * Create the health detail page on the given parent object.
 */

lv_obj_t *ui_health_detail_create(lv_obj_t *parent);

/**
 * Update the heart rate display and history list.
 */

void ui_health_detail_update(void);

#endif /* __UI_HEALTH_DETAIL_H */
