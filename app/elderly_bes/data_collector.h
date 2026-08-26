/****************************************************************************
 * apps/examples/elderly/data_collector.h
 *
 * Data collector: periodic sensor data collection, alarm detection,
 * and data upload via HTTP.
 ****************************************************************************/

#ifndef __DATA_COLLECTOR_H
#define __DATA_COLLECTOR_H

#include "ui_common.h"

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/**
 * Initialize the data collector module.
 * Starts the background collection task.
 */

void data_collector_init(void);

/**
 * 更新传感器数据到全局上下文。
 * 主循环中每帧调用一次。
 */

void data_collector_update(void);

/**
 * Stop the data collector.
 */

void data_collector_stop(void);

/**
 * Trigger an SOS alarm manually.
 */

void data_collector_trigger_sos(void);

/**
 * Get the latest vital data.
 */

const vital_data_t *data_collector_get_vitals(void);

/**
 * Check if vital signs are abnormal (for alarm detection).
 */

bool data_collector_check_abnormal(const vital_data_t *v);

#endif /* __DATA_COLLECTOR_H */
