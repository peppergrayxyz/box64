// SPDX-License-Identifier: MIT
#if !(defined(GO) && defined(GOM) && defined(GO2) && defined(DATA))
#error Meh...
#endif

//clockid_t is uint32?
// pid_t is uint32 too? (for clock_getcpuclockid)
// time_t is uint32?
// mqd_t is int

GOM(aio_cancel, iFEip)
// aio_cancel64
GO(aio_error, iFp)
GO2(aio_error64, iFp, aio_error)
GO(aio_fsync, iFip)
GO2(aio_fsync64, iFip, aio_fsync)
GO(aio_init, vFp)
GOM(aio_read, iFEp)
GO2(aio_read64, iFEp, my_aio_read)
GO(aio_return, lFp)
GO2(aio_return64, lFp, aio_return)
GO(aio_suspend, iFpip)
GO2(aio_suspend64, iFpip, aio_suspend)
GOM(aio_write, iFEp)
GO2(aio_write64, iFEp, my_aio_write)
GO(clock_getcpuclockid, iFip)
GO(clock_getres, iFip)
GO(clock_gettime, iFip)
GO(clock_nanosleep, iFiipp)
GO(clock_settime, iFip)
GOM(lio_listio, iFEipip)
// lio_listio64
GO(mq_close, iFi)
GO(mq_getattr, iFip)
GOM(mq_notify, iFEip)
GO(mq_open, iFpONN)
GO(__mq_open_2, iFpO)
GO(mq_receive, lFipLp)
GO(mq_send, iFipLu)
GO(mq_setattr, iFipp)
GO(mq_timedreceive, lFipLpp)
GO(mq_timedsend, iFipLup)
GO(mq_unlink, iFp)
GO(shm_open, iFpOu)
GO(shm_unlink, iFp)
GOM(timer_create, iFEipp)
GO(timer_delete, iFp)
GO(timer_getoverrun, iFp)
GO(timer_gettime, iFpp)
GO(timer_settime, iFpipp)
