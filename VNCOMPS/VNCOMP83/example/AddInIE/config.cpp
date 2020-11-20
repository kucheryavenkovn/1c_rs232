#include "stdafx.h"
#include "config.h"
#include "AddInIE_i.h"

const IID LIBID_AddInWebLib = LIBID_AddInIELib;

LPCOLESTR sAppId = _T(ADDNIE); //L"AddInIE";
//---------------------------------------------------------------------------//
LPCOLESTR sAddInServiceEx = L"AddInIE.AddInServiceEx";
//---------------------------------------------------------------------------//
LPCOLESTR sAddInSite = L"AddInIE.AddInSite";
//---------------------------------------------------------------------------//
LPCOLESTR sAdapterCOM = L"AddInIE.AdapterCOM";
//---------------------------------------------------------------------------//
LPCOLESTR sAdapterNative = L"AddInIE.AdapterNative";
//---------------------------------------------------------------------------//

#if _WIN64
const wchar_t *nameFilePrj = _T(ADDNIE) L"64.dll";
const wchar_t *nameFileComponent = _T(ADDNNATIVE) L"Win64_" _T(ADDNVER) L".dll";
#else
const wchar_t *nameFilePrj = _T(ADDNIE) L"32.dll";
const wchar_t *nameFileComponent = _T(ADDNNATIVE) L"Win32_" _T(ADDNVER) L".dll";
#endif
const AddInComponentType typeComponent = eAddInNative;
