// serpent.cpp - written and placed in the public domain by Wei Dai

/* Adapted for TrueCrypt */

#ifdef TC_WINDOWS_BOOT
#pragma optimize ("t", on)
#endif

// GWAT
//#include "Serpent.h"
#ifndef HEADER_Crypto_Serpent
#define HEADER_Crypto_Serpent

//#include "/home/arthur/Desktop/truecrypt-7.1a-source/Common/Tcdefs.h"
/*
 Legal Notice: Some portions of the source code contained in this file were
 derived from the source code of Encryption for the Masses 2.02a, which is
 Copyright (c) 1998-2000 Paul Le Roux and which is governed by the 'License
 Agreement for Encryption for the Masses'. Modifications and additions to
 the original source code (contained in this file) and all other portions
 of this file are Copyright (c) 2003-2010 TrueCrypt Developers Association
 and are governed by the TrueCrypt License 3.0 the full text of which is
 contained in the file License.txt included in TrueCrypt binary and source
 code distribution packages. */

#ifndef TCDEFS_H
#define TCDEFS_H

#define TC_APP_NAME						"TrueCrypt"

// Version displayed to user 
#define VERSION_STRING					"7.1a"

// Version number to compare against driver
#define VERSION_NUM						0x071a

// Release date
#define TC_STR_RELEASE_DATE				"February 7, 2012"
#define TC_RELEASE_DATE_YEAR			2012
#define TC_RELEASE_DATE_MONTH			2

#define BYTES_PER_KB                    1024LL
#define BYTES_PER_MB                    1048576LL
#define BYTES_PER_GB                    1073741824LL
#define BYTES_PER_TB                    1099511627776LL
#define BYTES_PER_PB                    1125899906842624LL

/* GUI/driver errors */

#define WIDE(x) (LPWSTR)L##x

#ifdef _MSC_VER

typedef __int8 int8;
typedef __int16 int16;
typedef __int32 int32;
typedef unsigned __int8 byte;
typedef unsigned __int16 uint16;
typedef unsigned __int32 uint32;

#ifdef TC_NO_COMPILER_INT64
typedef unsigned __int32	TC_LARGEST_COMPILER_UINT;
#else
typedef unsigned __int64	TC_LARGEST_COMPILER_UINT;
typedef __int64 int64;
typedef unsigned __int64 uint64;
#endif

#else // !_MSC_VER

#include <inttypes.h>
#include <limits.h>

typedef int8_t int8;
typedef int16_t int16;
typedef int32_t int32;
typedef int64_t int64;
typedef uint8_t byte;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef uint64_t uint64;

#if UCHAR_MAX != 0xffU
#error UCHAR_MAX != 0xff
#endif
#define __int8 char

#if USHRT_MAX != 0xffffU
#error USHRT_MAX != 0xffff
#endif
#define __int16 short

#if UINT_MAX != 0xffffffffU
#error UINT_MAX != 0xffffffff
#endif
#define __int32 int

typedef uint64 TC_LARGEST_COMPILER_UINT;

#define BOOL int
#ifndef FALSE
#define FALSE 0
#define TRUE 1
#endif

#endif // !_MSC_VER

#define TC_INT_TYPES_DEFINED

// Integer types required by Cryptolib
typedef unsigned __int8 uint_8t;
typedef unsigned __int16 uint_16t;
typedef unsigned __int32 uint_32t;
#ifndef TC_NO_COMPILER_INT64
typedef uint64 uint_64t;
#endif

typedef union 
{
	struct 
	{
		unsigned __int32 LowPart;
		unsigned __int32 HighPart;
	};
#ifndef TC_NO_COMPILER_INT64
	uint64 Value;
#endif

} UINT64_STRUCT;

#ifdef TC_WINDOWS_BOOT

#	ifdef  __cplusplus
extern "C"
#	endif
void ThrowFatalException (int line);

#	define TC_THROW_FATAL_EXCEPTION	ThrowFatalException (__LINE__)
#elif defined (TC_WINDOWS_DRIVER)
#	define TC_THROW_FATAL_EXCEPTION KeBugCheckEx (SECURITY_SYSTEM, __LINE__, 0, 0, 'TC')
#else
#	define TC_THROW_FATAL_EXCEPTION	*(char *) 0 = 0
#endif

#ifdef TC_WINDOWS_DRIVER

#include <ntifs.h>
#include <ntddk.h>		/* Standard header file for nt drivers */
#include <ntdddisk.h>		/* Standard I/O control codes  */

#define TCalloc(size) ((void *) ExAllocatePoolWithTag( NonPagedPool, size, 'MMCT' ))
#define TCfree(memblock) ExFreePoolWithTag( memblock, 'MMCT' )

#define DEVICE_DRIVER

#ifndef BOOL
typedef int BOOL;
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE !TRUE
#endif

#else				/* !TC_WINDOWS_DRIVER */

#define TCalloc malloc
#define TCfree free

#ifdef _WIN32

#ifndef TC_LOCAL_WIN32_WINNT_OVERRIDE
#	undef _WIN32_WINNT
#	define	_WIN32_WINNT 0x0501	/* Does not apply to the driver */
#endif

#include <windows.h>		/* Windows header */
#include <commctrl.h>		/* The common controls */
#include <process.h>		/* Process control */
#include <winioctl.h>
#include <stdio.h>		/* For sprintf */

#endif				/* _WIN32 */

#endif				/* !TC_WINDOWS_DRIVER */

#ifndef TC_TO_STRING
#	define TC_TO_STRING2(n) #n
#	define TC_TO_STRING(n) TC_TO_STRING2(n)
#endif

#ifdef DEVICE_DRIVER
#	if defined (DEBUG) || 0
#		if 1 // DbgPrintEx is not available on Windows 2000
#			define Dump DbgPrint
#		else
#			define Dump(...) DbgPrintEx (DPFLTR_IHVDRIVER_ID, DPFLTR_ERROR_LEVEL, __VA_ARGS__)
#		endif
#		define DumpMem(...) DumpMemory (__VA_ARGS__)
#	else
#		define Dump(...)
#		define DumpMem(...)
#	endif
#endif

#if !defined (trace_msg) && !defined (TC_WINDOWS_BOOT)
#	ifdef DEBUG
#		ifdef DEVICE_DRIVER
#			define trace_msg Dump
#		elif defined (_WIN32)
#			define trace_msg(...) do { char msg[2048]; _snprintf (msg, sizeof (msg), __VA_ARGS__); OutputDebugString (msg); } while (0)
#		endif
#		define trace_point trace_msg (__FUNCTION__ ":" TC_TO_STRING(__LINE__) "\n")
#	else
#		define trace_msg(...)
#		define trace_point
#	endif
#endif

#ifdef DEVICE_DRIVER
#	define TC_EVENT KEVENT
#	define TC_WAIT_EVENT(EVENT) KeWaitForSingleObject (&EVENT, Executive, KernelMode, FALSE, NULL)
#elif defined (_WIN32)
#	define TC_EVENT HANDLE
#	define TC_WAIT_EVENT(EVENT) WaitForSingleObject (EVENT, INFINITE)
#endif

#ifdef _WIN32
#define burn(mem,size) do { volatile char *burnm = (volatile char *)(mem); int burnc = size; RtlSecureZeroMemory (mem, size); while (burnc--) *burnm++ = 0; } while (0)
#else
#define burn(mem,size) do { volatile char *burnm = (volatile char *)(mem); int burnc = size; while (burnc--) *burnm++ = 0; } while (0)
#endif

// The size of the memory area to wipe is in bytes amd it must be a multiple of 8.
#ifndef TC_NO_COMPILER_INT64
#	define FAST_ERASE64(mem,size) do { volatile uint64 *burnm = (volatile uint64 *)(mem); int burnc = size >> 3; while (burnc--) *burnm++ = 0; } while (0)
#else
#	define FAST_ERASE64(mem,size) do { volatile unsigned __int32 *burnm = (volatile unsigned __int32 *)(mem); int burnc = size >> 2; while (burnc--) *burnm++ = 0; } while (0)
#endif

#ifdef TC_WINDOWS_BOOT
#	ifndef max
#		define max(a,b) (((a) > (b)) ? (a) : (b))
#	endif

#	ifdef  __cplusplus
extern "C"
#	endif
void EraseMemory (void *memory, int size);

#	undef burn
#	define burn EraseMemory
#endif

#ifdef MAX_PATH
#define TC_MAX_PATH		MAX_PATH
#else
#define TC_MAX_PATH		260	/* Includes the null terminator */
#endif

#define TC_STR_RELEASED_BY "Released by TrueCrypt Foundation on " TC_STR_RELEASE_DATE

#define MAX_URL_LENGTH	2084 /* Internet Explorer limit. Includes the terminating null character. */

#define TC_HOMEPAGE "http://www.truecrypt.org/"
#define TC_APPLINK "http://www.truecrypt.org/applink?version=" VERSION_STRING
#define TC_APPLINK_SECURE "https://www.truecrypt.org/applink?version=" VERSION_STRING

enum
{
	/* WARNING: ADD ANY NEW CODES AT THE END (DO NOT INSERT THEM BETWEEN EXISTING). DO *NOT* DELETE ANY 
	EXISTING CODES! Changing these values or their meanings may cause incompatibility with other versions
	(for example, if a new version of the TrueCrypt installer receives an error code from an installed 
	driver whose version is lower, it will report and interpret the error incorrectly). */

	ERR_SUCCESS								= 0,
	ERR_OS_ERROR							= 1,
	ERR_OUTOFMEMORY							= 2,
	ERR_PASSWORD_WRONG						= 3,
	ERR_VOL_FORMAT_BAD						= 4,
	ERR_DRIVE_NOT_FOUND						= 5,
	ERR_FILES_OPEN							= 6,
	ERR_VOL_SIZE_WRONG						= 7,
	ERR_COMPRESSION_NOT_SUPPORTED			= 8,
	ERR_PASSWORD_CHANGE_VOL_TYPE			= 9,
	ERR_PASSWORD_CHANGE_VOL_VERSION			= 10,
	ERR_VOL_SEEKING							= 11,
	ERR_VOL_WRITING							= 12,
	ERR_FILES_OPEN_LOCK						= 13,
	ERR_VOL_READING							= 14,
	ERR_DRIVER_VERSION						= 15,
	ERR_NEW_VERSION_REQUIRED				= 16,
	ERR_CIPHER_INIT_FAILURE					= 17,
	ERR_CIPHER_INIT_WEAK_KEY				= 18,
	ERR_SELF_TESTS_FAILED					= 19,
	ERR_SECTOR_SIZE_INCOMPATIBLE			= 20,
	ERR_VOL_ALREADY_MOUNTED					= 21,
	ERR_NO_FREE_DRIVES						= 22,
	ERR_FILE_OPEN_FAILED					= 23,
	ERR_VOL_MOUNT_FAILED					= 24,
	DEPRECATED_ERR_INVALID_DEVICE			= 25,
	ERR_ACCESS_DENIED						= 26,
	ERR_MODE_INIT_FAILED					= 27,
	ERR_DONT_REPORT							= 28,
	ERR_ENCRYPTION_NOT_COMPLETED			= 29,
	ERR_PARAMETER_INCORRECT					= 30,
	ERR_SYS_HIDVOL_HEAD_REENC_MODE_WRONG	= 31,
	ERR_NONSYS_INPLACE_ENC_INCOMPLETE		= 32,
	ERR_USER_ABORT							= 33
};

#endif 	// #ifndef TCDEFS_H

#ifdef __cplusplus
extern "C"
{
#endif

void serpent_set_key(const unsigned __int8 userKey[], int keylen, unsigned __int8 *ks);
void serpent_encrypt(const unsigned __int8 *inBlock, unsigned __int8 *outBlock, unsigned __int8 *ks);
void serpent_decrypt(const unsigned __int8 *inBlock,  unsigned __int8 *outBlock, unsigned __int8 *ks);

#ifdef __cplusplus
}
#endif

#endif // HEADER_Crypto_Serpent
//END GWAT

// GWAT
//#include "/home/arthur/Desktop/truecrypt-7.1a-source/Common/Endian.h"
/*
 Legal Notice: Some portions of the source code contained in this file were
 derived from the source code of Encryption for the Masses 2.02a, which is
 Copyright (c) 1998-2000 Paul Le Roux and which is governed by the 'License
 Agreement for Encryption for the Masses'. Modifications and additions to
 the original source code (contained in this file) and all other portions
 of this file are Copyright (c) 2003-2009 TrueCrypt Developers Association
 and are governed by the TrueCrypt License 3.0 the full text of which is
 contained in the file License.txt included in TrueCrypt binary and source
 code distribution packages. */

#ifndef TC_ENDIAN_H
#define TC_ENDIAN_H

//#include "/home/arthur/Desktop/truecrypt-7.1a-source/Common/Tcdefs.h"

#if defined(__cplusplus)
extern "C"
{
#endif

#ifdef _WIN32

#	ifndef LITTLE_ENDIAN
#		define LITTLE_ENDIAN 1234
#	endif
#	ifndef BYTE_ORDER
#		define BYTE_ORDER LITTLE_ENDIAN
#	endif

#elif !defined(BYTE_ORDER)

#	ifdef TC_MACOSX
#		include <machine/endian.h>
#	elif defined (TC_BSD)
#		include <sys/endian.h>
#	elif defined (TC_SOLARIS)
#		include <sys/types.h>
#		define LITTLE_ENDIAN 1234
#		define BIG_ENDIAN 4321
#		ifdef _BIG_ENDIAN
#			define BYTE_ORDER BIG_ENDIAN
#		else
#			define BYTE_ORDER LITTLE_ENDIAN
#		endif
#	else
#		include <endian.h>
#	endif

#	ifndef BYTE_ORDER
#		ifndef __BYTE_ORDER
#			error Byte order cannot be determined (BYTE_ORDER undefined)
#		endif

#		define BYTE_ORDER __BYTE_ORDER
#	endif

#	ifndef LITTLE_ENDIAN
#		define LITTLE_ENDIAN __LITTLE_ENDIAN
#	endif

#	ifndef BIG_ENDIAN
#		define BIG_ENDIAN __BIG_ENDIAN
#	endif

#endif // !BYTE_ORDER

/* Macros to read and write 16, 32, and 64-bit quantities in a portable manner.
   These functions are implemented as macros rather than true functions as
   the need to adjust the memory pointers makes them somewhat painful to call
   in user code */

#define mputInt64(memPtr,data) \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 56 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 48 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 40 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 32 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 24 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 16 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 8 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( data ) & 0xFF )

#define mputLong(memPtr,data) \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 24 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 16 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 8 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( data ) & 0xFF )

#define mputWord(memPtr,data) \
	*memPtr++ = ( unsigned char ) ( ( ( data ) >> 8 ) & 0xFF ), \
	*memPtr++ = ( unsigned char ) ( ( data ) & 0xFF )

#define mputByte(memPtr,data)	\
	*memPtr++ = ( unsigned char ) data

#define mputBytes(memPtr,data,len)  \
	memcpy (memPtr,data,len); \
	memPtr += len;

#define mgetInt64(memPtr) 		\
	( memPtr += 8, ( ( unsigned __int64 ) memPtr[ -8 ] << 56 ) | ( ( unsigned __int64 ) memPtr[ -7 ] << 48 ) | \
	( ( unsigned __int64 ) memPtr[ -6 ] << 40 ) | ( ( unsigned __int64 ) memPtr[ -5 ] << 32 ) | \
	( ( unsigned __int64 ) memPtr[ -4 ] << 24 ) | ( ( unsigned __int64 ) memPtr[ -3 ] << 16 ) | \
	  ( ( unsigned __int64 ) memPtr[ -2 ] << 8 ) | ( unsigned __int64 ) memPtr[ -1 ] )

#define mgetLong(memPtr) 		\
	( memPtr += 4, ( ( unsigned __int32 ) memPtr[ -4 ] << 24 ) | ( ( unsigned __int32 ) memPtr[ -3 ] << 16 ) | \
	  ( ( unsigned __int32 ) memPtr[ -2 ] << 8 ) | ( unsigned __int32 ) memPtr[ -1 ] )

#define mgetWord(memPtr) 		\
	( memPtr += 2, ( unsigned short ) memPtr[ -2 ] << 8 ) | ( ( unsigned short ) memPtr[ -1 ] ) 

#define mgetByte(memPtr)		\
	( ( unsigned char ) *memPtr++ )

#if BYTE_ORDER == BIG_ENDIAN
#	define LE16(x) MirrorBytes16(x)
#	define LE32(x) MirrorBytes32(x)
#	define LE64(x) MirrorBytes64(x)
#else
#	define LE16(x) (x)
#	define LE32(x) (x)
#	define LE64(x) (x)
#endif

#if BYTE_ORDER == LITTLE_ENDIAN
#	define BE16(x) MirrorBytes16(x)
#	define BE32(x) MirrorBytes32(x)
#	define BE64(x) MirrorBytes64(x)
#else
#	define BE16(x) (x)
#	define BE32(x) (x)
#	define BE64(x) (x)
#endif

unsigned __int16 MirrorBytes16 (unsigned __int16 x);
unsigned __int32 MirrorBytes32 (unsigned __int32 x);
#ifndef TC_NO_COMPILER_INT64
uint64 MirrorBytes64 (uint64 x);
#endif 
void LongReverse ( unsigned __int32 *buffer , unsigned byteCount );

#if defined(__cplusplus)
}
#endif

#endif /* TC_ENDIAN_H */
//END GWAT

#include <memory.h>

// GWAT
#include <cuda.h>
#include <cuda_runtime_api.h>

#if defined(_WIN32) && !defined(_DEBUG)
#include <stdlib.h>
#define rotlFixed _rotl
#define rotrFixed _rotr
#else
#define rotlFixed(x,n)   (((x) << (n)) | ((x) >> (32 - (n))))
#define rotrFixed(x,n)   (((x) >> (n)) | ((x) << (32 - (n))))
#endif

// linear transformation
#define LT(i,a,b,c,d,e)	{\
	a = rotlFixed(a, 13);	\
	c = rotlFixed(c, 3); 	\
	d = rotlFixed(d ^ c ^ (a << 3), 7); 	\
	b = rotlFixed(b ^ a ^ c, 1); 	\
	a = rotlFixed(a ^ b ^ d, 5); 		\
	c = rotlFixed(c ^ d ^ (b << 7), 22);}

// inverse linear transformation
#define ILT(i,a,b,c,d,e)	{\
	c = rotrFixed(c, 22);	\
	a = rotrFixed(a, 5); 	\
	c ^= d ^ (b << 7);	\
	a ^= b ^ d; 		\
	b = rotrFixed(b, 1); 	\
	d = rotrFixed(d, 7) ^ c ^ (a << 3);	\
	b ^= a ^ c; 		\
	c = rotrFixed(c, 3); 	\
	a = rotrFixed(a, 13);}

// order of output from S-box functions
#define beforeS0(f) f(0,a,b,c,d,e)
#define afterS0(f) f(1,b,e,c,a,d)
#define afterS1(f) f(2,c,b,a,e,d)
#define afterS2(f) f(3,a,e,b,d,c)
#define afterS3(f) f(4,e,b,d,c,a)
#define afterS4(f) f(5,b,a,e,c,d)
#define afterS5(f) f(6,a,c,b,e,d)
#define afterS6(f) f(7,a,c,d,b,e)
#define afterS7(f) f(8,d,e,b,a,c)

// order of output from inverse S-box functions
#define beforeI7(f) f(8,a,b,c,d,e)
#define afterI7(f) f(7,d,a,b,e,c)
#define afterI6(f) f(6,a,b,c,e,d)
#define afterI5(f) f(5,b,d,e,c,a)
#define afterI4(f) f(4,b,c,e,a,d)
#define afterI3(f) f(3,a,b,e,c,d)
#define afterI2(f) f(2,b,d,e,c,a)
#define afterI1(f) f(1,a,b,c,e,d)
#define afterI0(f) f(0,a,d,b,e,c)

// The instruction sequences for the S-box functions 
// come from Dag Arne Osvik's paper "Speeding up Serpent".

#define S0(i, r0, r1, r2, r3, r4) \
       {           \
    r3 ^= r0;   \
    r4 = r1;   \
    r1 &= r3;   \
    r4 ^= r2;   \
    r1 ^= r0;   \
    r0 |= r3;   \
    r0 ^= r4;   \
    r4 ^= r3;   \
    r3 ^= r2;   \
    r2 |= r1;   \
    r2 ^= r4;   \
    r4 = ~r4;      \
    r4 |= r1;   \
    r1 ^= r3;   \
    r1 ^= r4;   \
    r3 |= r0;   \
    r1 ^= r3;   \
    r4 ^= r3;   \
            }

#define I0(i, r0, r1, r2, r3, r4) \
       {           \
    r2 = ~r2;      \
    r4 = r1;   \
    r1 |= r0;   \
    r4 = ~r4;      \
    r1 ^= r2;   \
    r2 |= r4;   \
    r1 ^= r3;   \
    r0 ^= r4;   \
    r2 ^= r0;   \
    r0 &= r3;   \
    r4 ^= r0;   \
    r0 |= r1;   \
    r0 ^= r2;   \
    r3 ^= r4;   \
    r2 ^= r1;   \
    r3 ^= r0;   \
    r3 ^= r1;   \
    r2 &= r3;   \
    r4 ^= r2;   \
            }

#define S1(i, r0, r1, r2, r3, r4) \
       {           \
    r0 = ~r0;      \
    r2 = ~r2;      \
    r4 = r0;   \
    r0 &= r1;   \
    r2 ^= r0;   \
    r0 |= r3;   \
    r3 ^= r2;   \
    r1 ^= r0;   \
    r0 ^= r4;   \
    r4 |= r1;   \
    r1 ^= r3;   \
    r2 |= r0;   \
    r2 &= r4;   \
    r0 ^= r1;   \
    r1 &= r2;   \
    r1 ^= r0;   \
    r0 &= r2;   \
    r0 ^= r4;   \
            }

#define I1(i, r0, r1, r2, r3, r4) \
       {           \
    r4 = r1;   \
    r1 ^= r3;   \
    r3 &= r1;   \
    r4 ^= r2;   \
    r3 ^= r0;   \
    r0 |= r1;   \
    r2 ^= r3;   \
    r0 ^= r4;   \
    r0 |= r2;   \
    r1 ^= r3;   \
    r0 ^= r1;   \
    r1 |= r3;   \
    r1 ^= r0;   \
    r4 = ~r4;      \
    r4 ^= r1;   \
    r1 |= r0;   \
    r1 ^= r0;   \
    r1 |= r4;   \
    r3 ^= r1;   \
            }

#define S2(i, r0, r1, r2, r3, r4) \
       {           \
    r4 = r0;   \
    r0 &= r2;   \
    r0 ^= r3;   \
    r2 ^= r1;   \
    r2 ^= r0;   \
    r3 |= r4;   \
    r3 ^= r1;   \
    r4 ^= r2;   \
    r1 = r3;   \
    r3 |= r4;   \
    r3 ^= r0;   \
    r0 &= r1;   \
    r4 ^= r0;   \
    r1 ^= r3;   \
    r1 ^= r4;   \
    r4 = ~r4;      \
            }

#define I2(i, r0, r1, r2, r3, r4) \
       {           \
    r2 ^= r3;   \
    r3 ^= r0;   \
    r4 = r3;   \
    r3 &= r2;   \
    r3 ^= r1;   \
    r1 |= r2;   \
    r1 ^= r4;   \
    r4 &= r3;   \
    r2 ^= r3;   \
    r4 &= r0;   \
    r4 ^= r2;   \
    r2 &= r1;   \
    r2 |= r0;   \
    r3 = ~r3;      \
    r2 ^= r3;   \
    r0 ^= r3;   \
    r0 &= r1;   \
    r3 ^= r4;   \
    r3 ^= r0;   \
            }

#define S3(i, r0, r1, r2, r3, r4) \
       {           \
    r4 = r0;   \
    r0 |= r3;   \
    r3 ^= r1;   \
    r1 &= r4;   \
    r4 ^= r2;   \
    r2 ^= r3;   \
    r3 &= r0;   \
    r4 |= r1;   \
    r3 ^= r4;   \
    r0 ^= r1;   \
    r4 &= r0;   \
    r1 ^= r3;   \
    r4 ^= r2;   \
    r1 |= r0;   \
    r1 ^= r2;   \
    r0 ^= r3;   \
    r2 = r1;   \
    r1 |= r3;   \
    r1 ^= r0;   \
            }

#define I3(i, r0, r1, r2, r3, r4) \
       {           \
    r4 = r2;   \
    r2 ^= r1;   \
    r1 &= r2;   \
    r1 ^= r0;   \
    r0 &= r4;   \
    r4 ^= r3;   \
    r3 |= r1;   \
    r3 ^= r2;   \
    r0 ^= r4;   \
    r2 ^= r0;   \
    r0 |= r3;   \
    r0 ^= r1;   \
    r4 ^= r2;   \
    r2 &= r3;   \
    r1 |= r3;   \
    r1 ^= r2;   \
    r4 ^= r0;   \
    r2 ^= r4;   \
            }

#define S4(i, r0, r1, r2, r3, r4) \
       {           \
    r1 ^= r3;   \
    r3 = ~r3;      \
    r2 ^= r3;   \
    r3 ^= r0;   \
    r4 = r1;   \
    r1 &= r3;   \
    r1 ^= r2;   \
    r4 ^= r3;   \
    r0 ^= r4;   \
    r2 &= r4;   \
    r2 ^= r0;   \
    r0 &= r1;   \
    r3 ^= r0;   \
    r4 |= r1;   \
    r4 ^= r0;   \
    r0 |= r3;   \
    r0 ^= r2;   \
    r2 &= r3;   \
    r0 = ~r0;      \
    r4 ^= r2;   \
            }

#define I4(i, r0, r1, r2, r3, r4) \
       {           \
    r4 = r2;   \
    r2 &= r3;   \
    r2 ^= r1;   \
    r1 |= r3;   \
    r1 &= r0;   \
    r4 ^= r2;   \
    r4 ^= r1;   \
    r1 &= r2;   \
    r0 = ~r0;      \
    r3 ^= r4;   \
    r1 ^= r3;   \
    r3 &= r0;   \
    r3 ^= r2;   \
    r0 ^= r1;   \
    r2 &= r0;   \
    r3 ^= r0;   \
    r2 ^= r4;   \
    r2 |= r3;   \
    r3 ^= r0;   \
    r2 ^= r1;   \
            }

#define S5(i, r0, r1, r2, r3, r4) \
       {           \
    r0 ^= r1;   \
    r1 ^= r3;   \
    r3 = ~r3;      \
    r4 = r1;   \
    r1 &= r0;   \
    r2 ^= r3;   \
    r1 ^= r2;   \
    r2 |= r4;   \
    r4 ^= r3;   \
    r3 &= r1;   \
    r3 ^= r0;   \
    r4 ^= r1;   \
    r4 ^= r2;   \
    r2 ^= r0;   \
    r0 &= r3;   \
    r2 = ~r2;      \
    r0 ^= r4;   \
    r4 |= r3;   \
    r2 ^= r4;   \
            }

#define I5(i, r0, r1, r2, r3, r4) \
       {           \
    r1 = ~r1;      \
    r4 = r3;   \
    r2 ^= r1;   \
    r3 |= r0;   \
    r3 ^= r2;   \
    r2 |= r1;   \
    r2 &= r0;   \
    r4 ^= r3;   \
    r2 ^= r4;   \
    r4 |= r0;   \
    r4 ^= r1;   \
    r1 &= r2;   \
    r1 ^= r3;   \
    r4 ^= r2;   \
    r3 &= r4;   \
    r4 ^= r1;   \
    r3 ^= r0;   \
    r3 ^= r4;   \
    r4 = ~r4;      \
            }

#define S6(i, r0, r1, r2, r3, r4) \
       {           \
    r2 = ~r2;      \
    r4 = r3;   \
    r3 &= r0;   \
    r0 ^= r4;   \
    r3 ^= r2;   \
    r2 |= r4;   \
    r1 ^= r3;   \
    r2 ^= r0;   \
    r0 |= r1;   \
    r2 ^= r1;   \
    r4 ^= r0;   \
    r0 |= r3;   \
    r0 ^= r2;   \
    r4 ^= r3;   \
    r4 ^= r0;   \
    r3 = ~r3;      \
    r2 &= r4;   \
    r2 ^= r3;   \
            }

#define I6(i, r0, r1, r2, r3, r4) \
       {           \
    r0 ^= r2;   \
    r4 = r2;   \
    r2 &= r0;   \
    r4 ^= r3;   \
    r2 = ~r2;      \
    r3 ^= r1;   \
    r2 ^= r3;   \
    r4 |= r0;   \
    r0 ^= r2;   \
    r3 ^= r4;   \
    r4 ^= r1;   \
    r1 &= r3;   \
    r1 ^= r0;   \
    r0 ^= r3;   \
    r0 |= r2;   \
    r3 ^= r1;   \
    r4 ^= r0;   \
            }

#define S7(i, r0, r1, r2, r3, r4) \
       {           \
    r4 = r2;   \
    r2 &= r1;   \
    r2 ^= r3;   \
    r3 &= r1;   \
    r4 ^= r2;   \
    r2 ^= r1;   \
    r1 ^= r0;   \
    r0 |= r4;   \
    r0 ^= r2;   \
    r3 ^= r1;   \
    r2 ^= r3;   \
    r3 &= r0;   \
    r3 ^= r4;   \
    r4 ^= r2;   \
    r2 &= r0;   \
    r4 = ~r4;      \
    r2 ^= r4;   \
    r4 &= r0;   \
    r1 ^= r3;   \
    r4 ^= r1;   \
            }

#define I7(i, r0, r1, r2, r3, r4) \
       {           \
    r4 = r2;   \
    r2 ^= r0;   \
    r0 &= r3;   \
    r2 = ~r2;      \
    r4 |= r3;   \
    r3 ^= r1;   \
    r1 |= r0;   \
    r0 ^= r2;   \
    r2 &= r4;   \
    r1 ^= r2;   \
    r2 ^= r0;   \
    r0 |= r2;   \
    r3 &= r4;   \
    r0 ^= r3;   \
    r4 ^= r1;   \
    r3 ^= r4;   \
    r4 |= r0;   \
    r3 ^= r2;   \
    r4 ^= r2;   \
            }

// key xor
#define KX(r, a, b, c, d, e)	{\
	a ^= k[4 * r + 0]; \
	b ^= k[4 * r + 1]; \
	c ^= k[4 * r + 2]; \
	d ^= k[4 * r + 3];}


#ifdef TC_MINIMIZE_CODE_SIZE

static void S0f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{
	*r3 ^= *r0;
	*r4 = *r1;
	*r1 &= *r3;
	*r4 ^= *r2;
	*r1 ^= *r0;
	*r0 |= *r3;
	*r0 ^= *r4;
	*r4 ^= *r3;
	*r3 ^= *r2;
	*r2 |= *r1;
	*r2 ^= *r4;
	*r4 = ~*r4;
	*r4 |= *r1;
	*r1 ^= *r3;
	*r1 ^= *r4;
	*r3 |= *r0;
	*r1 ^= *r3;
	*r4 ^= *r3;
}

static void S1f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{        
    *r0 = ~*r0;   
    *r2 = ~*r2;   
    *r4 = *r0;
    *r0 &= *r1;
    *r2 ^= *r0;
    *r0 |= *r3;
    *r3 ^= *r2;
    *r1 ^= *r0;
    *r0 ^= *r4;
    *r4 |= *r1;
    *r1 ^= *r3;
    *r2 |= *r0;
    *r2 &= *r4;
    *r0 ^= *r1;
    *r1 &= *r2;
    *r1 ^= *r0;
    *r0 &= *r2;
    *r0 ^= *r4;
}

static void S2f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{        
	*r4 = *r0;
	*r0 &= *r2;
	*r0 ^= *r3;
	*r2 ^= *r1;
	*r2 ^= *r0;
	*r3 |= *r4;
	*r3 ^= *r1;
	*r4 ^= *r2;
	*r1 = *r3;
	*r3 |= *r4;
	*r3 ^= *r0;
	*r0 &= *r1;
	*r4 ^= *r0;
	*r1 ^= *r3;
	*r1 ^= *r4;
	*r4 = ~*r4;   
}

static void S3f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{        
	*r4 = *r0;
	*r0 |= *r3;
	*r3 ^= *r1;
	*r1 &= *r4;
	*r4 ^= *r2;
	*r2 ^= *r3;
	*r3 &= *r0;
	*r4 |= *r1;
	*r3 ^= *r4;
	*r0 ^= *r1;
	*r4 &= *r0;
	*r1 ^= *r3;
	*r4 ^= *r2;
	*r1 |= *r0;
	*r1 ^= *r2;
	*r0 ^= *r3;
	*r2 = *r1;
	*r1 |= *r3;
	*r1 ^= *r0;
}

static void S4f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{        
	*r1 ^= *r3;
	*r3 = ~*r3;   
	*r2 ^= *r3;
	*r3 ^= *r0;
	*r4 = *r1;
	*r1 &= *r3;
	*r1 ^= *r2;
	*r4 ^= *r3;
	*r0 ^= *r4;
	*r2 &= *r4;
	*r2 ^= *r0;
	*r0 &= *r1;
	*r3 ^= *r0;
	*r4 |= *r1;
	*r4 ^= *r0;
	*r0 |= *r3;
	*r0 ^= *r2;
	*r2 &= *r3;
	*r0 = ~*r0;   
	*r4 ^= *r2;
}

static void S5f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{        
	*r0 ^= *r1;
	*r1 ^= *r3;
	*r3 = ~*r3;   
	*r4 = *r1;
	*r1 &= *r0;
	*r2 ^= *r3;
	*r1 ^= *r2;
	*r2 |= *r4;
	*r4 ^= *r3;
	*r3 &= *r1;
	*r3 ^= *r0;
	*r4 ^= *r1;
	*r4 ^= *r2;
	*r2 ^= *r0;
	*r0 &= *r3;
	*r2 = ~*r2;   
	*r0 ^= *r4;
	*r4 |= *r3;
	*r2 ^= *r4;
}

static void S6f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{        
	*r2 = ~*r2;   
	*r4 = *r3;
	*r3 &= *r0;
	*r0 ^= *r4;
	*r3 ^= *r2;
	*r2 |= *r4;
	*r1 ^= *r3;
	*r2 ^= *r0;
	*r0 |= *r1;
	*r2 ^= *r1;
	*r4 ^= *r0;
	*r0 |= *r3;
	*r0 ^= *r2;
	*r4 ^= *r3;
	*r4 ^= *r0;
	*r3 = ~*r3;   
	*r2 &= *r4;
	*r2 ^= *r3;
}

static void S7f (unsigned __int32 *r0, unsigned __int32 *r1, unsigned __int32 *r2, unsigned __int32 *r3, unsigned __int32 *r4)
{        
	*r4 = *r2;
	*r2 &= *r1;
	*r2 ^= *r3;
	*r3 &= *r1;
	*r4 ^= *r2;
	*r2 ^= *r1;
	*r1 ^= *r0;
	*r0 |= *r4;
	*r0 ^= *r2;
	*r3 ^= *r1;
	*r2 ^= *r3;
	*r3 &= *r0;
	*r3 ^= *r4;
	*r4 ^= *r2;
	*r2 &= *r0;
	*r4 = ~*r4;   
	*r2 ^= *r4;
	*r4 &= *r0;
	*r1 ^= *r3;
	*r4 ^= *r1;
}

static void KXf (const unsigned __int32 *k, unsigned int r, unsigned __int32 *a, unsigned __int32 *b, unsigned __int32 *c, unsigned __int32 *d)
{
	*a ^= k[r];
	*b ^= k[r + 1];
	*c ^= k[r + 2];
	*d ^= k[r + 3];
}

#endif // TC_MINIMIZE_CODE_SIZE

#ifndef TC_MINIMIZE_CODE_SIZE

void serpent_set_key(const unsigned __int8 userKey[], int keylen, unsigned __int8 *ks)
{
	unsigned __int32 a,b,c,d,e;
	unsigned __int32 *k = (unsigned __int32 *)ks;
	unsigned __int32 t;
	int i;

	for (i = 0; i < keylen / (int)sizeof(__int32); i++)
		k[i] = LE32(((unsigned __int32*)userKey)[i]);

	if (keylen < 32)
		k[keylen/4] |= (unsigned __int32)1 << ((keylen%4)*8);

	k += 8;
	t = k[-1];
	for (i = 0; i < 132; ++i)
		k[i] = t = rotlFixed(k[i-8] ^ k[i-5] ^ k[i-3] ^ t ^ 0x9e3779b9 ^ i, 11);
	k -= 20;

#define LK(r, a, b, c, d, e)	{\
	a = k[(8-r)*4 + 0];		\
	b = k[(8-r)*4 + 1];		\
	c = k[(8-r)*4 + 2];		\
	d = k[(8-r)*4 + 3];}

#define SK(r, a, b, c, d, e)	{\
	k[(8-r)*4 + 4] = a;		\
	k[(8-r)*4 + 5] = b;		\
	k[(8-r)*4 + 6] = c;		\
	k[(8-r)*4 + 7] = d;}	\

	for (i=0; i<4; i++)
	{
		afterS2(LK); afterS2(S3); afterS3(SK);
		afterS1(LK); afterS1(S2); afterS2(SK);
		afterS0(LK); afterS0(S1); afterS1(SK);
		beforeS0(LK); beforeS0(S0); afterS0(SK);
		k += 8*4;
		afterS6(LK); afterS6(S7); afterS7(SK);
		afterS5(LK); afterS5(S6); afterS6(SK);
		afterS4(LK); afterS4(S5); afterS5(SK);
		afterS3(LK); afterS3(S4); afterS4(SK);
	}
	afterS2(LK); afterS2(S3); afterS3(SK);
}

#else // TC_MINIMIZE_CODE_SIZE

static void LKf (unsigned __int32 *k, unsigned int r, unsigned __int32 *a, unsigned __int32 *b, unsigned __int32 *c, unsigned __int32 *d)
{
	*a = k[r];
	*b = k[r + 1];
	*c = k[r + 2];
	*d = k[r + 3];
}

static void SKf (unsigned __int32 *k, unsigned int r, unsigned __int32 *a, unsigned __int32 *b, unsigned __int32 *c, unsigned __int32 *d)
{
	k[r + 4] = *a;
	k[r + 5] = *b;
	k[r + 6] = *c;
	k[r + 7] = *d;
}

void serpent_set_key(const unsigned __int8 userKey[], int keylen, unsigned __int8 *ks)
{
	unsigned __int32 a,b,c,d,e;
	unsigned __int32 *k = (unsigned __int32 *)ks;
	unsigned __int32 t;
	int i;

	for (i = 0; i < keylen / (int)sizeof(__int32); i++)
		k[i] = LE32(((unsigned __int32*)userKey)[i]);

	if (keylen < 32)
		k[keylen/4] |= (unsigned __int32)1 << ((keylen%4)*8);

	k += 8;
	t = k[-1];
	for (i = 0; i < 132; ++i)
		k[i] = t = rotlFixed(k[i-8] ^ k[i-5] ^ k[i-3] ^ t ^ 0x9e3779b9 ^ i, 11);
	k -= 20;

	for (i=0; i<4; i++)
	{
		LKf (k, 20, &a, &e, &b, &d); S3f (&a, &e, &b, &d, &c); SKf (k, 16, &e, &b, &d, &c);
		LKf (k, 24, &c, &b, &a, &e); S2f (&c, &b, &a, &e, &d); SKf (k, 20, &a, &e, &b, &d);
		LKf (k, 28, &b, &e, &c, &a); S1f (&b, &e, &c, &a, &d); SKf (k, 24, &c, &b, &a, &e);
		LKf (k, 32, &a, &b, &c, &d); S0f (&a, &b, &c, &d, &e); SKf (k, 28, &b, &e, &c, &a);
		k += 8*4;
		LKf (k,  4, &a, &c, &d, &b); S7f (&a, &c, &d, &b, &e); SKf (k,  0, &d, &e, &b, &a);
		LKf (k,  8, &a, &c, &b, &e); S6f (&a, &c, &b, &e, &d); SKf (k,  4, &a, &c, &d, &b);
		LKf (k, 12, &b, &a, &e, &c); S5f (&b, &a, &e, &c, &d); SKf (k,  8, &a, &c, &b, &e);
		LKf (k, 16, &e, &b, &d, &c); S4f (&e, &b, &d, &c, &a); SKf (k, 12, &b, &a, &e, &c);
	}
	LKf (k, 20, &a, &e, &b, &d); S3f (&a, &e, &b, &d, &c); SKf (k, 16, &e, &b, &d, &c);
}

#endif // TC_MINIMIZE_CODE_SIZE


#ifndef TC_MINIMIZE_CODE_SIZE

void serpent_encrypt(const unsigned __int8 *inBlock, unsigned __int8 *outBlock, unsigned __int8 *ks)
{
	unsigned __int32 a, b, c, d, e;
	unsigned int i=1;
	const unsigned __int32 *k = (unsigned __int32 *)ks + 8;
	unsigned __int32 *in = (unsigned __int32 *) inBlock;
	unsigned __int32 *out = (unsigned __int32 *) outBlock;

    a = LE32(in[0]);
	b = LE32(in[1]);
	c = LE32(in[2]);
	d = LE32(in[3]);

	do
	{
		beforeS0(KX); beforeS0(S0); afterS0(LT);
		afterS0(KX); afterS0(S1); afterS1(LT);
		afterS1(KX); afterS1(S2); afterS2(LT);
		afterS2(KX); afterS2(S3); afterS3(LT);
		afterS3(KX); afterS3(S4); afterS4(LT);
		afterS4(KX); afterS4(S5); afterS5(LT);
		afterS5(KX); afterS5(S6); afterS6(LT);
		afterS6(KX); afterS6(S7);

		if (i == 4)
			break;

		++i;
		c = b;
		b = e;
		e = d;
		d = a;
		a = e;
		k += 32;
		beforeS0(LT);
	}
	while (1);

	afterS7(KX);
	
    out[0] = LE32(d);
	out[1] = LE32(e);
	out[2] = LE32(b);
	out[3] = LE32(a);
}

#else // TC_MINIMIZE_CODE_SIZE

typedef unsigned __int32 uint32;

static void LTf (uint32 *a, uint32 *b, uint32 *c, uint32 *d)
{
	*a = rotlFixed(*a, 13);
	*c = rotlFixed(*c, 3);
	*d = rotlFixed(*d ^ *c ^ (*a << 3), 7);
	*b = rotlFixed(*b ^ *a ^ *c, 1);
	*a = rotlFixed(*a ^ *b ^ *d, 5);
	*c = rotlFixed(*c ^ *d ^ (*b << 7), 22);
}

void serpent_encrypt(const unsigned __int8 *inBlock, unsigned __int8 *outBlock, unsigned __int8 *ks)
{
	unsigned __int32 a, b, c, d, e;
	unsigned int i=1;
	const unsigned __int32 *k = (unsigned __int32 *)ks + 8;
	unsigned __int32 *in = (unsigned __int32 *) inBlock;
	unsigned __int32 *out = (unsigned __int32 *) outBlock;

    a = LE32(in[0]);
	b = LE32(in[1]);
	c = LE32(in[2]);
	d = LE32(in[3]);

	do
	{
		KXf (k,  0, &a, &b, &c, &d); S0f (&a, &b, &c, &d, &e); LTf (&b, &e, &c, &a);
		KXf (k,  4, &b, &e, &c, &a); S1f (&b, &e, &c, &a, &d); LTf (&c, &b, &a, &e);
		KXf (k,  8, &c, &b, &a, &e); S2f (&c, &b, &a, &e, &d); LTf (&a, &e, &b, &d);
		KXf (k, 12, &a, &e, &b, &d); S3f (&a, &e, &b, &d, &c); LTf (&e, &b, &d, &c);
		KXf (k, 16, &e, &b, &d, &c); S4f (&e, &b, &d, &c, &a); LTf (&b, &a, &e, &c);
		KXf (k, 20, &b, &a, &e, &c); S5f (&b, &a, &e, &c, &d); LTf (&a, &c, &b, &e);
		KXf (k, 24, &a, &c, &b, &e); S6f (&a, &c, &b, &e, &d); LTf (&a, &c, &d, &b);
		KXf (k, 28, &a, &c, &d, &b); S7f (&a, &c, &d, &b, &e);

		if (i == 4)
			break;

		++i;
		c = b;
		b = e;
		e = d;
		d = a;
		a = e;
		k += 32;
		LTf (&a,&b,&c,&d);
	}
	while (1);

	KXf (k, 32, &d, &e, &b, &a);
	
    out[0] = LE32(d);
	out[1] = LE32(e);
	out[2] = LE32(b);
	out[3] = LE32(a);
}

#endif // TC_MINIMIZE_CODE_SIZE

#if !defined (TC_MINIMIZE_CODE_SIZE) || defined (TC_WINDOWS_BOOT_SERPENT)

void serpent_decrypt(const unsigned __int8 *inBlock, unsigned __int8 *outBlock, unsigned __int8 *ks)
{
	unsigned __int32 a, b, c, d, e;
	const unsigned __int32 *k = (unsigned __int32 *)ks + 104;
	unsigned int i=4;
	unsigned __int32 *in = (unsigned __int32 *) inBlock;
	unsigned __int32 *out = (unsigned __int32 *) outBlock;

    a = LE32(in[0]);
	b = LE32(in[1]);
	c = LE32(in[2]);
	d = LE32(in[3]);

	beforeI7(KX);
	goto start;

	do
	{
		c = b;
		b = d;
		d = e;
		k -= 32;
		beforeI7(ILT);
start:
		beforeI7(I7); afterI7(KX); 
		afterI7(ILT); afterI7(I6); afterI6(KX); 
		afterI6(ILT); afterI6(I5); afterI5(KX); 
		afterI5(ILT); afterI5(I4); afterI4(KX); 
		afterI4(ILT); afterI4(I3); afterI3(KX); 
		afterI3(ILT); afterI3(I2); afterI2(KX); 
		afterI2(ILT); afterI2(I1); afterI1(KX); 
		afterI1(ILT); afterI1(I0); afterI0(KX);
	}
	while (--i != 0);
	
    out[0] = LE32(a);
	out[1] = LE32(d);
	out[2] = LE32(b);
	out[3] = LE32(e);
}

#else // TC_MINIMIZE_CODE_SIZE && !TC_WINDOWS_BOOT_SERPENT

static void ILTf (uint32 *a, uint32 *b, uint32 *c, uint32 *d)
{ 
	*c = rotrFixed(*c, 22);
	*a = rotrFixed(*a, 5);
	*c ^= *d ^ (*b << 7);
	*a ^= *b ^ *d;
	*b = rotrFixed(*b, 1);
	*d = rotrFixed(*d, 7) ^ *c ^ (*a << 3);
	*b ^= *a ^ *c;
	*c = rotrFixed(*c, 3);
	*a = rotrFixed(*a, 13);
}

void serpent_decrypt(const unsigned __int8 *inBlock, unsigned __int8 *outBlock, unsigned __int8 *ks)
{
	unsigned __int32 a, b, c, d, e;
	const unsigned __int32 *k = (unsigned __int32 *)ks + 104;
	unsigned int i=4;
	unsigned __int32 *in = (unsigned __int32 *) inBlock;
	unsigned __int32 *out = (unsigned __int32 *) outBlock;

    a = LE32(in[0]);
	b = LE32(in[1]);
	c = LE32(in[2]);
	d = LE32(in[3]);

	KXf (k, 32, &a, &b, &c, &d);
	goto start;

	do
	{
		c = b;
		b = d;
		d = e;
		k -= 32;
		beforeI7(ILT);
start:
		beforeI7(I7); KXf (k, 28, &d, &a, &b, &e);
		ILTf (&d, &a, &b, &e); afterI7(I6); KXf (k, 24, &a, &b, &c, &e); 
		ILTf (&a, &b, &c, &e); afterI6(I5); KXf (k, 20, &b, &d, &e, &c); 
		ILTf (&b, &d, &e, &c); afterI5(I4); KXf (k, 16, &b, &c, &e, &a); 
		ILTf (&b, &c, &e, &a); afterI4(I3); KXf (k, 12, &a, &b, &e, &c);
		ILTf (&a, &b, &e, &c); afterI3(I2); KXf (k, 8,  &b, &d, &e, &c);
		ILTf (&b, &d, &e, &c); afterI2(I1); KXf (k, 4,  &a, &b, &c, &e);
		ILTf (&a, &b, &c, &e); afterI1(I0); KXf (k, 0,  &a, &d, &b, &e);
	}
	while (--i != 0);
	
    out[0] = LE32(a);
	out[1] = LE32(d);
	out[2] = LE32(b);
	out[3] = LE32(e);
}

#endif // TC_MINIMIZE_CODE_SIZE && !TC_WINDOWS_BOOT_SERPENT
