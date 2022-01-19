-- project
set_project("mold")
set_version("1.0.1")
set_targetdir("$(projectdir)")

-- Define options, e.g. `xmake f --lto=y`
option("lto", {showmenu = true, default = false, description = "Enable LTO"})

-- Add build modes, e.g. `xmake f -m debug`
add_rules("mode.debug", "mode.release", "mode.asan", "mode.tsan")

-- Set third-party packages, we do not use ./third-party codes
add_requires("tbb", "xxhash", "zlib")
if not is_plat("macosx") then
    add_requires("openssl")
end

-- By default, we want to use mimalloc as a memory allocator. mimalloc
-- is disabled when ASAN or TSAN is on, as they are not compatible.
-- It's also disabled on macOS and Android because it didn't work on
-- those hosts.
if not is_plat("macosx", "android") and not is_mode("asan", "tsan") then
    add_requires("mimalloc")
end

-- Set common configuraion
set_languages("c++20")
add_cxflags("-fPIE", "-fno-unwind-tables", "-fno-asynchronous-unwind-tables")
add_cxxflags("-fno-exceptions")
if is_plat("android") then
    -- -Wc++11-narrowing is a fatal error on Android, so disable it.
    add_cxxflags("-Wno-c++11-narrowing")
elseif is_plat("linux") then
    add_syslinks("pthread", "dl", "m")
end

-- Enable lto
if has_config("lto") then
    add_cxxflags("-flto")
    add_ldflags("-flto")
    set_optimize("fastest")
end

-- Define targets
target("mold")
    set_kind("binary")
    add_files("*.cc")
    add_files("elf/*.cc")
    add_files("macho/*.cc")
    add_packages("tbb", "mimalloc", "xxhash", "openssl", "zlib")

    on_load(function (target)
        target:add("defines", "MOLD_VERSION=\"" .. target:version() .. "\"")
        if os.isdir("$(projectdir)/.git") then
            import("devel.git")
            local githash = git.lastcommit({repodir = os.projectdir()})
            if githash then
                target:add("defines", "GIT_HASH=\"" .. githash .. "\"")
            end
        end
    end)

    after_build(function (target)
        os.cd(os.projectdir())
        os.tryrm("ld")
        os.tryrm("ld64.mold")
        os.ln("mold", "ld")
        os.ln("mold", "ld64.mold")
    end)

target("mold-wrapper")
    set_kind("shared")
    set_default(false)
    add_files("elf/mold-wrapper.c")
