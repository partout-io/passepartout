// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace Passepartout.Development {
    // Windows implements this COM interface for activating registered packaged apps.
    // This GUID is its fixed interface ID (IID), independent of our package identity.
    [ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IApplicationActivationManager {
        void ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string appId,
            [MarshalAs(UnmanagedType.LPWStr)] string arguments, uint options, out uint processId);
        void ActivateForFile(IntPtr appId, IntPtr items, IntPtr verb, out uint processId);
        void ActivateForProtocol(IntPtr appId, IntPtr items, out uint processId);
    }

    public static class Activation {
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern SafeFileHandle OpenProcess(uint access, bool inherit, uint processId);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenProcessToken(SafeFileHandle process, uint access, out SafeFileHandle token);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(SafeFileHandle token, int informationClass,
            out uint information, uint length, out uint returnedLength);

        public static uint Launch(string appId, string arguments) {
            // Windows' fixed ApplicationActivationManager class ID (CLSID).
            var manager = (IApplicationActivationManager)Activator.CreateInstance(
                Type.GetTypeFromCLSID(new Guid("45ba127d-10a8-46ea-8ab7-56ea9078943c")));
            try {
                uint processId;
                manager.ActivateApplication(appId, arguments, 0, out processId);
                return processId;
            } finally {
                Marshal.FinalReleaseComObject(manager);
            }
        }

        public static bool IsAppContainer(uint processId) {
            using (var process = OpenProcess(0x1000, false, processId)) {
                if (process.IsInvalid) throw new Win32Exception();
                SafeFileHandle token;
                if (!OpenProcessToken(process, 0x0008, out token)) throw new Win32Exception();
                using (token) {
                    uint value, length;
                    // TOKEN_INFORMATION_CLASS::TokenIsAppContainer = 29.
                    if (!GetTokenInformation(token, 29, out value, 4, out length))
                        throw new Win32Exception();
                    return value != 0;
                }
            }
        }
    }
}
