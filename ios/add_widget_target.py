#!/usr/bin/env python3
"""Add WidgetKit extension target to Flutter iOS pbxproj."""

import uuid
import sys

PBXPROJ = '/home/jphermans/projects/ai-balance-flutter/ios/Runner.xcodeproj/project.pbxproj'

def gen_id():
    return uuid.uuid4().hex.upper()[:24]

# Generate all IDs upfront
ids = {k: gen_id() for k in [
    'bf_bundle','bf_widget','bf_provider','bf_info','bf_entitlements','bf_appex',
    'fr_bundle','fr_widget','fr_provider','fr_info','fr_entitlements','fr_appex',
    'group','sources','resources','target','conf_list',
    'conf_dbg','conf_rel','conf_prof','embed_phase',
    'proxy','dep'
]}

# Print IDs for debugging
for k, v in ids.items():
    print(f'{k}={v}')

with open(PBXPROJ, 'r') as f:
    content = f.read()

# 1. PBXBuildFile: add widget source + resource bf + embed appex bf
content = content.replace(
    '/* End PBXBuildFile section */',
    f'''\t\t{ids['bf_bundle']} /* BalanceWidgetBundle.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ids['fr_bundle']} /* BalanceWidgetBundle.swift */; }};
\t\t{ids['bf_widget']} /* BalanceWidget.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ids['fr_widget']} /* BalanceWidget.swift */; }};
\t\t{ids['bf_provider']} /* BalanceProvider.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ids['fr_provider']} /* BalanceProvider.swift */; }};
\t\t{ids['bf_info']} /* Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['fr_info']} /* Info.plist */; }};
\t\t{ids['bf_entitlements']} /* BalanceWidget.entitlements in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['fr_entitlements']} /* BalanceWidget.entitlements */; }};
\t\t{ids['bf_appex']} /* BalanceWidgetExtension.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {ids['fr_appex']} /* BalanceWidgetExtension.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};
/* End PBXBuildFile section */'''
)

# 2. PBXContainerItemProxy: add widget proxy
content = content.replace(
    '/* End PBXContainerItemProxy section */',
    f'''\t\t{ids['proxy']} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 97C146E61CF9000F007C117D /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {ids['target']};
\t\t\tremoteInfo = BalanceWidgetExtension;
\t\t}};
/* End PBXContainerItemProxy section */'''
)

# 3. PBXFileReference: add widget files + product
content = content.replace(
    '/* End PBXFileReference section */',
    f'''\t\t{ids['fr_bundle']} /* BalanceWidgetBundle.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BalanceWidgetBundle.swift; sourceTree = "<group>"; }};
\t\t{ids['fr_widget']} /* BalanceWidget.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BalanceWidget.swift; sourceTree = "<group>"; }};
\t\t{ids['fr_provider']} /* BalanceProvider.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BalanceProvider.swift; sourceTree = "<group>"; }};
\t\t{ids['fr_info']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
\t\t{ids['fr_entitlements']} /* BalanceWidget.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = BalanceWidget.entitlements; sourceTree = "<group>"; }};
\t\t{ids['fr_appex']} /* BalanceWidgetExtension.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = BalanceWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */'''
)

# 4. PBXGroup: add BalanceWidget group
content = content.replace(
    '/* End PBXGroup section */',
    f'''\t\t{ids['group']} /* BalanceWidget */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{ids['fr_bundle']} /* BalanceWidgetBundle.swift */,
\t\t\t\t{ids['fr_widget']} /* BalanceWidget.swift */,
\t\t\t\t{ids['fr_provider']} /* BalanceProvider.swift */,
\t\t\t\t{ids['fr_info']} /* Info.plist */,
\t\t\t\t{ids['fr_entitlements']} /* BalanceWidget.entitlements */,
\t\t\t);
\t\t\tpath = BalanceWidget;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */'''
)

# 5. Add BalanceWidget group to root group (97C146E5)
content = content.replace(
    '\t\t\t\t331C8082294A63A400263BE5 /* RunnerTests */,',
    f'\t\t\t\t331C8082294A63A400263BE5 /* RunnerTests */,\n\t\t\t\t{ids["group"]} /* BalanceWidget */,'
)

# 6. Add .appex to Products group
content = content.replace(
    '\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,',
    f'\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,\n\t\t\t\t{ids["fr_appex"]} /* BalanceWidgetExtension.appex */,'
)

# 7. PBXNativeTarget: add widget target
content = content.replace(
    '/* End PBXNativeTarget section */',
    f'''\t\t{ids['target']} /* BalanceWidgetExtension */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {ids['conf_list']} /* Build configuration list for PBXNativeTarget "BalanceWidgetExtension" */;
\t\t\tbuildPhases = (
\t\t\t\t{ids['sources']} /* Sources */,
\t\t\t\t{ids['resources']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = BalanceWidgetExtension;
\t\t\tproductName = BalanceWidgetExtension;
\t\t\tproductReference = {ids['fr_appex']} /* BalanceWidgetExtension.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};
/* End PBXNativeTarget section */'''
)

# 8. Add Embed App Extensions phase to Runner target buildPhases
content = content.replace(
    '\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,',
    f'\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,\n\t\t\t\t{ids["embed_phase"]} /* Embed App Extensions */,'
)

# 9. Add widget to project targets array
content = content.replace(
    '\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,',
    f'\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,\n\t\t\t\t{ids["target"]} /* BalanceWidgetExtension */,'
)

# 10. PBXSourcesBuildPhase: add widget sources phase
content = content.replace(
    '/* End PBXSourcesBuildPhase section */',
    f'''\t\t{ids['sources']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{ids['bf_bundle']} /* BalanceWidgetBundle.swift in Sources */,
\t\t\t\t{ids['bf_widget']} /* BalanceWidget.swift in Sources */,
\t\t\t\t{ids['bf_provider']} /* BalanceProvider.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */'''
)

# 11. PBXResourcesBuildPhase: add widget resources phase
content = content.replace(
    '/* End PBXResourcesBuildPhase section */',
    f'''\t\t{ids['resources']} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{ids['bf_info']} /* Info.plist in Resources */,
\t\t\t\t{ids['bf_entitlements']} /* BalanceWidget.entitlements in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */'''
)

# 12. PBXCopyFilesBuildPhase: Embed App Extensions
content = content.replace(
    '/* End PBXCopyFilesBuildPhase section */',
    f'''\t\t{ids['embed_phase']} /* Embed App Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t{ids['bf_appex']} /* BalanceWidgetExtension.appex in Embed App Extensions */,
\t\t\t);
\t\t\tname = "Embed App Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXCopyFilesBuildPhase section */'''
)

# 13. PBXTargetDependency
content = content.replace(
    '/* End PBXTargetDependency section */',
    f'''\t\t{ids['dep']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {ids['target']} /* BalanceWidgetExtension */;
\t\t\ttargetProxy = {ids['proxy']} /* PBXContainerItemProxy */;
\t\t}};
/* End PBXTargetDependency section */'''
)

# 14. Add widget target dependency to Runner target
content = content.replace(
    '\t\t\tdependencies = (\n\t\t\t);\n\t\t\tname = Runner;',
    f'\t\t\tdependencies = (\n\t\t\t\t{ids["dep"]} /* PBXTargetDependency */,\n\t\t\t);\n\t\t\tname = Runner;'
)

# 15. Add TargetAttributes for widget
content = content.replace(
    '\t\t\t\t\t97C146ED1CF9000F007C117D = {\n\t\t\t\t\t\tCreatedOnToolsVersion = 7.3.1;\n\t\t\t\t\t\tLastSwiftMigration = 1100;\n\t\t\t\t\t};',
    f'''\t\t\t\t\t97C146ED1CF9000F007C117D = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 7.3.1;
\t\t\t\t\t\tLastSwiftMigration = 1100;
\t\t\t\t\t}};
\t\t\t\t\t{ids["target"]} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.4;
\t\t\t\t\t}};'''
)

# Helper: widget build config template
def _widget_config(id_, name, extra_settings):
    return f'''\t\t{id_} /* {name} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_IDENTITY = "iPhone Developer";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tDEVELOPMENT_TEAM = "ABC123DEF4";
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "";
\t\t\t\tINFOPLIST_FILE = BalanceWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.jphermans.aiBalanceTracker.BalanceWidget;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tCODE_SIGN_ENTITLEMENTS = BalanceWidget/BalanceWidget.entitlements;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = NO;
\t\t\t\t{extra_settings}
\t\t\t}};
\t\t\tname = {name};
\t\t}};'''

# 16. XCBuildConfiguration: inject 3 widget configs (Debug, Release, Profile)
debug_extras = '''SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;'''
content = content.replace(
    '/* End XCBuildConfiguration section */',
    _widget_config(ids['conf_dbg'], 'Debug', debug_extras) + '\n' +
    _widget_config(ids['conf_rel'], 'Release', 
        '''COPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;''') + '\n' +
    _widget_config(ids['conf_prof'], 'Profile',
        '''COPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;''') + '\n' +
    '/* End XCBuildConfiguration section */'
)

# 17. XCConfigurationList: add widget config list
content = content.replace(
    '/* End XCConfigurationList section */',
    f'''\t\t{ids['conf_list']} /* Build configuration list for PBXNativeTarget "BalanceWidgetExtension" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{ids['conf_dbg']} /* Debug */,
\t\t\t\t{ids['conf_rel']} /* Release */,
\t\t\t\t{ids['conf_prof']} /* Profile */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */'''
)

# Save
with open(PBXPROJ, 'w') as f:
    f.write(content)

print(f'\nPBXProject updated. New target ID: {ids["target"]}')
print('Verifying...')

# Quick validation
with open(PBXPROJ) as f:
    result = f.read()

checks = [
    ('BalanceWidget group', '/* BalanceWidget */'),
    ('Widget target', 'isa = PBXNativeTarget;\n\t\t\tbuildConfigurationList'),
    ('Product reference', 'BalanceWidgetExtension.appex'),
    ('Embed phase', 'Embed App Extensions'),
    ('Target in project', f'{ids["target"]} /* BalanceWidgetExtension */'),
    ('Build files', 'BalanceWidgetBundle.swift in Sources'),
    ('Widget Resources Phase', 'Info.plist in Resources'),
    ('BalanceWidget.entitlements', 'BalanceWidget.entitlements in Resources'),
]

all_ok = True
for name, pattern in checks:
    ok = pattern in result
    print(f'  {"✓" if ok else "✗"} {name}')
    if not ok:
        all_ok = False

if all_ok:
    print('\nAll checks passed!')
else:
    print('\nSome checks failed - review pbxproj manually.')
    sys.exit(1)
