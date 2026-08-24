/****************************************************************************
 * apps/examples/elderly/ui_index.h
 *
 * Home/Index page: SOS button, vital signs cards, step progress.
 ****************************************************************************/

#ifndef __UI_INDEX_H
#define __UI_INDEX_H

#include "ui_common.h"

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * Create the index (home) page on the given parent object.
 * Returns the page container.
 */

lv_obj_t *ui_index_create(lv_obj_t *parent);

/**
 * Update vital sign display values.
 */

void ui_index_update_vitals(void);

/**
 * Update step counter and progress bar.
 */

void ui_index_update_steps(void);

/**
 * Update health status message at bottom.
 */

void ui_index_update_health_status(void);

#endif /* __UI_INDEX_H */
