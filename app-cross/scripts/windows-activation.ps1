# SPDX-FileCopyrightText: 2026 Davide De Rosa
# SPDX-License-Identifier: GPL-3.0

# Development tooling only: activate through Windows and inspect the resulting
# token. Starting the EXE directly is not an AppContainer activation.
if (-not ('Passepartout.Development.Activation' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace Passepartout.Development {
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
        static extern IntPtr OpenProcess(uint access, bool inherit, uint processId);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool OpenProcessToken(IntPtr process, uint access, out IntPtr token);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(IntPtr token, int informationClass,
            out uint information, uint length, out uint returnedLength);
        [DllImport("kernel32.dll")]
        static extern bool CloseHandle(IntPtr handle);

        public static uint Launch(string appId, string arguments) {
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
            var process = OpenProcess(0x1000, false, processId);
            if (process == IntPtr.Zero) throw new Win32Exception();
            try {
                IntPtr token;
                if (!OpenProcessToken(process, 0x0008, out token)) throw new Win32Exception();
                try {
                    uint value, length;
                    // TOKEN_INFORMATION_CLASS::TokenIsAppContainer = 29.
                    if (!GetTokenInformation(token, 29, out value, 4, out length))
                        throw new Win32Exception();
                    return value != 0;
                } finally {
                    CloseHandle(token);
                }
            } finally {
                CloseHandle(process);
            }
        }
    }
}
'@
}
