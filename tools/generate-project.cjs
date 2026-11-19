const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
let serial = 1;
const id = () => (serial++).toString(16).toUpperCase().padStart(24, '0');
const objects = [];
const add = (key, value) => objects.push(`${key} = { ${value} };`);
const quote = s => JSON.stringify(s);
const list = a => `(${a.join(',')}${a.length ? ',' : ''})`;
const project = id(), main = id(), products = id(), projectConfigs = id();
const commonFiles = ['Sources/RushCore/GameEngine.swift', 'Shared/GameModel.swift', 'Shared/RushTrack.swift'];
const definitions = [
  {name:'PerfectRush', files:[...commonFiles, 'iOS/PerfectRushApp.swift', 'iOS/PhoneGameView.swift'], sdk:'iphoneos', platforms:'iphoneos iphonesimulator', family:'1,2', bundle:'fr.theounniv.perfectrush', kind:'application'},
  {name:'PerfectRushWatch', files:[...commonFiles, 'Watch/PerfectRushWatchApp.swift', 'Watch/WatchGameView.swift'], sdk:'watchos', platforms:'watchos watchsimulator', family:'4', bundle:'fr.theounniv.perfectrush.watch', kind:'application'},
  {name:'PerfectRushTests', files:['Tests/RushCoreTests/GameEngineTests.swift'], sdk:'iphoneos', platforms:'iphoneos iphonesimulator', family:'1,2', bundle:'fr.theounniv.perfectrush.tests', kind:'bundle.unit-test'}
];
const refs = new Map();
for (const file of new Set(definitions.flatMap(t=>t.files))) {
  const key = id(); refs.set(file,key);
  add(key, `isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ${quote(file)}; sourceTree = SOURCE_ROOT;`);
}
for (const t of definitions) {
  t.id = id(); t.product = id(); t.configs = id(); t.sources = id(); t.frameworks=id(); t.resources=id();
  const ext = t.kind === 'application' ? 'app' : 'xctest';
  add(t.product, `isa = PBXFileReference; explicitFileType = ${t.kind === 'application' ? 'wrapper.application' : 'wrapper.cfbundle'}; includeInIndex = 0; path = ${t.name}.${ext}; sourceTree = BUILT_PRODUCTS_DIR;`);
  const builds = t.files.map(file=>{ const key=id(); add(key,`isa = PBXBuildFile; fileRef = ${refs.get(file)};`); return key; });
  add(t.sources, `isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ${list(builds)}; runOnlyForDeploymentPostprocessing = 0;`);
  for (const [key,isa] of [[t.frameworks,'PBXFrameworksBuildPhase'],[t.resources,'PBXResourcesBuildPhase']]) add(key, `isa = ${isa}; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;`);
  const configurations=[];
  for (const config of ['Debug','Release']) {
    const key=id(); configurations.push(key);
    const test=t.kind!=='application';
    const settings={
      PRODUCT_NAME:'$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER:t.bundle,
      SDKROOT:t.sdk, SUPPORTED_PLATFORMS:t.platforms, TARGETED_DEVICE_FAMILY:t.family,
      SWIFT_VERSION:'5.0', GENERATE_INFOPLIST_FILE:'YES', CODE_SIGN_STYLE:'Automatic',
      MARKETING_VERSION:'1.0', CURRENT_PROJECT_VERSION:'1',
      SWIFT_OPTIMIZATION_LEVEL:config==='Debug'?'-Onone':'-O',
      SWIFT_ACTIVE_COMPILATION_CONDITIONS:config==='Debug'?'DEBUG':'',
      ENABLE_TESTABILITY:config==='Debug'?'YES':'NO',
      ...(t.sdk==='watchos'?{WATCHOS_DEPLOYMENT_TARGET:'10.0', INFOPLIST_KEY_WKApplication:'YES', INFOPLIST_KEY_WKWatchOnly:'YES'}:{IPHONEOS_DEPLOYMENT_TARGET:'17.0'}),
      ...(test?{TEST_HOST:'$(BUILT_PRODUCTS_DIR)/PerfectRush.app/PerfectRush',BUNDLE_LOADER:'$(TEST_HOST)'}:{INFOPLIST_KEY_CFBundleDisplayName:'Perfect Rush',INFOPLIST_KEY_UILaunchScreen_Generation:'YES'}),
      ...(t.name==='PerfectRush'?{INFOPLIST_KEY_UIApplicationSceneManifest_Generation:'YES',INFOPLIST_KEY_UISupportedInterfaceOrientations:'UIInterfaceOrientationPortrait',INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad:'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'}:{})
    };
    add(key, `isa = XCBuildConfiguration; buildSettings = { ${Object.entries(settings).map(([k,v])=>`${k} = ${quote(v)};`).join(' ')} }; name = ${config};`);
  }
  add(t.configs, `isa = XCConfigurationList; buildConfigurations = ${list(configurations)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;`);
}
const test=definitions[2], phone=definitions[0];
const proxy=id(), dependency=id();
add(proxy, `isa = PBXContainerItemProxy; containerPortal = ${project}; proxyType = 1; remoteGlobalIDString = ${phone.id}; remoteInfo = PerfectRush;`);
add(dependency,`isa = PBXTargetDependency; target = ${phone.id}; targetProxy = ${proxy};`);
for(const t of definitions) add(t.id, `isa = PBXNativeTarget; buildConfigurationList = ${t.configs}; buildPhases = ${list([t.sources,t.frameworks,t.resources])}; buildRules = (); dependencies = ${list(t===test?[dependency]:[])}; name = ${t.name}; productName = ${t.name}; productReference = ${t.product}; productType = ${quote('com.apple.product-type.'+t.kind)};`);
add(main,`isa = PBXGroup; children = ${list([...refs.values(),products])}; sourceTree = "<group>";`);
add(products,`isa = PBXGroup; children = ${list(definitions.map(t=>t.product))}; name = Products; sourceTree = "<group>";`);
const pc=[];
for(const config of ['Debug','Release']) {const key=id();pc.push(key);add(key,`isa = XCBuildConfiguration; buildSettings = { CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; SWIFT_VERSION = 5.0; }; name = ${config};`);}
add(projectConfigs,`isa = XCConfigurationList; buildConfigurations = ${list(pc)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;`);
add(project,`isa = PBXProject; attributes = { BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1500; TargetAttributes = { ${definitions.map(t=>`${t.id} = { CreatedOnToolsVersion = 15.0; ${t===test?`TestTargetID = ${phone.id};`:''} };`).join(' ')} }; }; buildConfigurationList = ${projectConfigs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = fr; hasScannedForEncodings = 0; knownRegions = (fr,en,Base); mainGroup = ${main}; productRefGroup = ${products}; projectDirPath = ""; projectRoot = ""; targets = ${list(definitions.map(t=>t.id))};`);
const dir=path.join(root,'PerfectRush.xcodeproj');
fs.mkdirSync(path.join(dir,'xcshareddata','xcschemes'),{recursive:true});
fs.writeFileSync(path.join(dir,'project.pbxproj'),`// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n${objects.join('\n')}\n}; rootObject = ${project}; }\n`);
const buildable=t=>`<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${t.id}" BuildableName="${t.name}.${t.kind==='application'?'app':'xctest'}" BlueprintName="${t.name}" ReferencedContainer="container:PerfectRush.xcodeproj"/>`;
for(const t of definitions.slice(0,2)) {
const xml=`<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1500" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">${buildable(t)}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>${t===phone?`<TestableReference skipped="NO">${buildable(test)}</TestableReference>`:''}</Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">${buildable(t)}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">${buildable(t)}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>`;
fs.writeFileSync(path.join(dir,'xcshareddata','xcschemes',t.name+'.xcscheme'),xml+'\n');
}
console.log('Projet et deux schémas créés.');
