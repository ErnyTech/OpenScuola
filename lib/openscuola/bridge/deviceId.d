module openscuola.bridge.deviceId;

version (linux) {
    private enum SA_FAMILY_MAC = 17;
    version = Getifaddrs_Support;
} else version (OSX) {
    private enum SA_FAMILY_MAC = 18;
    version = Getifaddrs_Support;
}

extern(C) const(char)* c_getDeviceId(const char* hardwareId) {
    import std.string : toStringz, fromStringz;

    return getDeviceId(hardwareId.fromStringz.idup).toStringz;
}

extern(C) const(char)* c_generateRandomHardwareId() {
    import std.string : toStringz;

    return generateRandomHardwareId().toStringz;
}

extern(C) const(char)* c_getHardwareIdInterface(const char* netInterface) {
    import std.string : toStringz, fromStringz;

    return getHardwareIdInterface(netInterface.fromStringz.idup).toStringz;
}

extern(C) const(char)* c_getHardwareId() {
    import std.string : toStringz;

    return getHardwareId().toStringz;
}

public string getDeviceId(string hardwareId) {
    import std.digest.md : md5Of;
    import std.random : uniform;
    import std.format : format;

    string deviceId;
    auto md5Hash = md5Of(hardwareId);
    auto rand1 = cast(ubyte) uniform(0, ubyte.max);
    auto rand2 = cast(ubyte) uniform(0, ubyte.max);
    auto deviceIdHash = patchHash(md5Hash, rand1, rand2);

    foreach(i, elem; deviceIdHash) {
        deviceId ~= format!"%02x"(elem);
    }

    return deviceId;
}

public string generateRandomHardwareId() {
    import std.random : uniform;
    import std.array : array;
    import std.range : generate, takeExactly;
    import std.format : format;
    import std.uni : toUpper;

    string macAddrStr;
    ubyte[6] macAddr = generate!(() => cast(ubyte) uniform(0, ubyte.max)).takeExactly(6).array;

    macAddr[0] &= ~(1UL << 0);  // Unicast
    macAddr[0] &= ~(1UL << 1);  // Global

    foreach(elem; macAddr) {
        if (macAddrStr.length > 0) {
            macAddrStr ~= ":";
        }

        macAddrStr ~= format!"%02x"(elem);
    }

    return macAddrStr.toUpper;
}

public string getHardwareIdInterface(string netInterface) {
    import std.stdio : writeln;

    version(Getifaddrs_Support) {
        auto macAddr = getIfAddrsMac(netInterface);

        if (macAddr == null) {
            writeln("Error: A valid mac address was not found on the network card ", netInterface);
        }

        return macAddr;
    } else version(Windows) {
        writeln("FIX ME: getHardwareIdInterface is a stub in Windows, generating random hardware id");
        return generateRandomHardwareId();
    } else {
        static assert(0, "This operating system is not supported");
    }
}

public string getHardwareId() {
    import std.stdio : writeln;

    version(Getifaddrs_Support) {
        import std.algorithm.searching : canFind;

        auto interfaces = getIfAddrsInterfaces();

        // Priority eth/en -> wlan/wlo -> other

        foreach (elem; interfaces) {
            if (elem.canFind("eth") || elem.canFind("en")) {
                auto macStr = getIfAddrsMac(elem);

                if (macStr != null) {
                    return macStr;
                }
            }
        }

        foreach (elem; interfaces) {
            if (elem.canFind("wlan") || elem.canFind("wlo")) {
                auto macStr = getIfAddrsMac(elem);

                if (macStr != null) {
                    return macStr;
                }
            }
        }

        foreach (elem; interfaces) {
            auto macStr = getIfAddrsMac(elem);

            if (macStr != null) {
                return macStr;
            }
        }

         writeln("Error: No network card with valid mac address was found");
        return null;
    } else version(Windows) {
        import core.sys.windows.iptypes : IP_ADAPTER_INFO;
        import core.sys.windows.windef : DWORD;
        import core.sys.windows.winerror : ERROR_SUCCESS;
        import core.sys.windows.ipifcons : MIB_IF_TYPE_ETHERNET;
        import std.format : format;
        import std.uni : toUpper;

        IP_ADAPTER_INFO[32] adapterInfo;
        DWORD dwBufLen = adapterInfo.sizeof;
        
        auto iphlpapi = Iphlpapi.get();

        if (iphlpapi is null || iphlpapi.GetAdaptersInfo is null) {
            writeln("Error: Failed to load Iphlpapi.dll");
            return null;
        }

        DWORD dwStatus = iphlpapi.GetAdaptersInfo(adapterInfo.ptr, &dwBufLen);

        if (dwStatus != ERROR_SUCCESS) {
            writeln("Error: Interfaces not found!");
            return null;
        }

        foreach (IP_ADAPTER_INFO networkInterface; adapterInfo) {
            if (networkInterface.Type != MIB_IF_TYPE_ETHERNET) {
                continue;
            }

            auto macArr = networkInterface.Address[0..6];
            auto unicast = (macArr[0] >> 0) & 1U;
            auto global = (macArr[0] >> 1) & 1U;

            if (unicast != 0 || global != 0) {
                continue;
            }

            return getMacStr(macArr);
        }

        return null;
    } else {
        static assert(0, "This operating system is not supported");
    }
}

version(OSX) {
    private struct sockaddr_dl {
        byte sdl_len;
        byte sdl_family;
        ushort sdl_index;
        byte sdl_type;
        byte sdl_nlen;
        byte sdl_alen;
        byte sdl_slen;
        ubyte[12] sdl_data;
    }
}

version(linux) {
    private struct sockaddr_ll {
        ushort sll_family;
        ushort sll_protocol;
        int sll_ifindex;
        ushort sll_hatype;
        ubyte sll_pkttype;
        ubyte sll_halen;
        ubyte[8] sll_addr;
    }
}

version(Windows) {
    import core.sys.windows.winbase : FreeLibrary, GetProcAddress, LoadLibraryA;
    import core.sys.windows.windef : DWORD, PULONG, HANDLE;
    import core.sys.windows.iptypes: PIP_ADAPTER_INFO;
    
    alias DWORD function(PIP_ADAPTER_INFO, PULONG) GetAdaptersInfoFunc;   
    
    struct Iphlpapi {
        GetAdaptersInfoFunc GetAdaptersInfo;
        
        static Iphlpapi* get() {
            if (handle != handle.init) {
                return &inst;
            }
            
            if ((handle = LoadLibraryA("Iphlpapi.dll")) != handle.init) {
                inst.GetAdaptersInfo = cast(GetAdaptersInfoFunc) GetProcAddress(handle, "GetAdaptersInfo");
                
                if (!inst.GetAdaptersInfo) {
                    return null;   
                }

                return &inst;
            }
            
            return null;
        }
	
	shared static ~this() {
	    if (handle != handle.init ) {
	        FreeLibrary(handle);
	    }
	}
		
	private:
	    __gshared Iphlpapi inst;
	    __gshared HANDLE  handle;
    }
}

private ubyte[] patchHash(ubyte[] hash, ubyte rand1, ubyte rand2) {
    hash[0] -= 0x28;
    hash[1] += 0x5b;
    hash[2] += 0x74;
    hash[3] -= 0x37;
    hash[4] -= 2;
    hash[5] -= 0x18;
    hash[6] += 0x3b;
    hash[7] -= 0x3b;
    hash[8] += 0x10;
    hash[9] += 0x53;
    hash[10] += 0x3f;
    hash[11] -= 0x2e;
    hash[12] -= 0x15;
    hash[13] += 0x3a;
    hash[14] += 0x7f;
    hash[15] += 0x8e;

    foreach(i, ref elem; hash) {
        auto randIndex = rand1 * (i + 1);
        elem += randIndex + rand2;
    }

    hash ~= rand1;
    hash ~= rand2;
    return hash;
}

private ubyte[] getMacUbyte(string macStr) {
    import std.string : split;
    import std.conv : to;

    ubyte[] macAddr;

    foreach(elem; macStr.split(":")) {
        macAddr ~= elem.to!ubyte(16);
    }

    return macAddr;
}

private string getMacStr(ubyte[] macUbyte) {
    import std.conv : to;
    import std.uni : toUpper;
    import std.format : format;

    string macAddrStr;

    foreach(elem; macUbyte) {
        if (macAddrStr.length > 0) {
            macAddrStr ~= ":";
        }

        macAddrStr ~= format!"%02x"(elem);
    }

    return macAddrStr.toUpper;
}

version(Getifaddrs_Support) {
    private string[] getIfAddrsInterfaces() {
        version(linux) {
            import core.sys.linux.ifaddrs : getifaddrs, freeifaddrs, ifaddrs;
        }

        version(OSX) {
            import core.sys.darwin.ifaddrs : getifaddrs, freeifaddrs, ifaddrs;
        }

        import std.string : fromStringz;

        string[] interfaces;
        ifaddrs* ifap;

        if (getifaddrs(&ifap) != 0) {
            return [];
        }

        scope(exit) freeifaddrs(ifap);

        for (ifaddrs* ifaptr = ifap; ifaptr != null; ifaptr = ifaptr.ifa_next) {
            if (ifaptr.ifa_addr.sa_family != SA_FAMILY_MAC) {
                continue;
            }

            interfaces ~= ifaptr.ifa_name.fromStringz.idup;
        }

        return interfaces;
    }

    string getIfAddrsMac(string netInterface) {
        import std.stdio : writeln;

        version(linux) {
            import core.sys.linux.ifaddrs : getifaddrs, freeifaddrs, ifaddrs;
        }

        version(OSX) {
            import core.sys.darwin.ifaddrs : getifaddrs, freeifaddrs, ifaddrs;
        }

        import std.string : fromStringz;
        import std.algorithm.iteration : sum;

        ifaddrs* ifap;

        if (getifaddrs(&ifap) != 0) {
            writeln("Failed to obtain mac addresses! Check your permissions");
            return null;
        }

        scope(exit) freeifaddrs(ifap);

        for (ifaddrs* ifaptr = ifap; ifaptr != null; ifaptr = ifaptr.ifa_next) {
            if (ifaptr.ifa_addr.sa_family != SA_FAMILY_MAC) {
                continue;
            }

            if (ifaptr.ifa_name.fromStringz != netInterface) {
                continue;
            }

            version(linux) {
                auto socketAddrLL = cast(sockaddr_ll*) ifaptr.ifa_addr;
                auto macUbyte = socketAddrLL.sll_addr[0..6];
            }

            version(OSX) {
                auto socketAddrDL = cast(sockaddr_dl*) ifaptr.ifa_addr;
                auto macUbyte = (socketAddrDL.sdl_data.ptr + socketAddrDL.sdl_nlen)[0..6];
            }

            auto unicast = (macUbyte[0] >> 0) & 1U;
            auto global = (macUbyte[0] >> 1) & 1U;

            if (unicast != 0 || global != 0 || macUbyte.sum == 0) {
                return null;
            }

            return getMacStr(macUbyte);
        }

        return null;
    }
}
