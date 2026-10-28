/*
 * Source file for a minimal FF-A SP for usage with our qemu platform
 *
 * - it runs at S-EL0 level
 * - only uses direct messaging send/receive as communication mechanism 
 *   as direct messaging interfaces uses FF-A argument registers(x3-x7) for 
 *   request and response, hence we don't need to setup RX/TX buffers, for simplicity.
 * - that leads to us using FF-A SMC ABI directly
 *
 *
 *
 * */

#include <stdint.h>

#define FFA_MSG_WAIT			0x8400006B
#define FFA_MSG_SEND_DIRECT_RESP	0xC4000070

struct ffa_regs {
	uint64_t x0;
	uint64_t x1;
	uint64_t x2;
	uint64_t x3;
	uint64_t x4;
	uint64_t x5;
	uint64_t x6;
	uint64_t x7;
};

static inline void ffa_call(struct ffa_regs *r)
{

	register uint64_t x0 __asm__("x0") = r->x0;
	register uint64_t x1 __asm__("x1") = r->x1;
	register uint64_t x2 __asm__("x2") = r->x2;
	register uint64_t x3 __asm__("x3") = r->x3;
	register uint64_t x4 __asm__("x4") = r->x4;
	register uint64_t x5 __asm__("x5") = r->x5;
	register uint64_t x6 __asm__("x6") = r->x6;
	register uint64_t x7 __asm__("x7") = r->x7;


	__asm__ volatile("smc #0" 
			: "+r"(x0), "+r"(x1), "+r"(x2), "+r"(x3), "+r"(x4), "+r"(x5), "+r"(x6), "+r"(x7)
			: 
			: "memory");
	
	r->x0 = x0;
	r->x1 = x1;
	r->x2 = x2;
	r->x3 = x3;
	r->x4 = x4;
	r->x5 = x5;
	r->x6 = x6;
	r->x7 = x7;
}

/*
// Helper functions
static void ffa_wait(void)
{
	ffa_call(FFA_MSG_WAIT, 0, 0, 0, 0, 0, 0, 0);
}

static void ffa_direct_resp(uint64_t source_dest,
		uint64_t arg0, uint64_t arg1, uint64_t arg2, uint64_t arg3, uint64_t arg4)
{
	ffa_call(FFA_MSG_SEND_DIRECT_RESP, source_dest, 0, arg0, arg1, arg2, arg3, arg4)
}
*/

void sp_main(void)
{
	struct ffa_regs r;
	
	

	for (;;) {
		r.x0 = FFA_MSG_WAIT;
		r.x1 = 0;
		r.x2 = 0;
		r.x3 = 0;
		r.x4 = 0;
		r.x5 = 0;
		r.x6 = 0;
		r.x7 = 0;

		ffa_call(&r);
		

		/*
		 * When Hafnium resumes this SP for a direct request, the incoming request is in the FF-A registers.
		 *
		 * Return a known response.
		 */
		r.x0 = FFA_MSG_SEND_DIRECT_RESP;
		r.x1 = r.x1;	/* preserve the dest/src information returned by Hafnium */
		r.x2 = 0;
		r.x3 = 0x4d494e5350ULL; /* "MINSP" */
		r.x4 = 1;
		r.x5 = r.x5;
		r.x6 = 0;
		r.x7 = 0;

		ffa_call(&r);
	}
}
