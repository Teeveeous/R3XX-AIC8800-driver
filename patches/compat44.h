#ifndef AIC_COMPAT44_H
#define AIC_COMPAT44_H
#include <linux/version.h>
#include <linux/timer.h>
/* Vendor driver targets newer kernels; map the two renamed timer calls for 4.4. */
#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 2, 0)
#define timer_delete_sync del_timer_sync
#define timer_delete del_timer
#endif
#endif
