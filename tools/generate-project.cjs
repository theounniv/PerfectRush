// Projet de cours — Théo BOREL et Lana SCHMITT.
// Outil de maintenance : il écrit le projet Xcode et relie ses cibles.
// Pour travailler sur le jeu, ouvrir le .xcodeproj ; ne pas modifier cet outil.
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
// Paquets Swift Package Manager utilisés seulement par l'app iPhone (authentification).
const packages = [
  {key:id(), url:'https://github.com/firebase/firebase-ios-sdk.git', version:'12.0.0', products:['FirebaseCore','FirebaseAuth']},
  {key:id(), url:'https://github.com/google/GoogleSignIn-iOS.git', version:'9.0.0', products:['GoogleSignIn','GoogleSignInSwift']}
];
for (const p of packages) add(p.key, `isa = XCRemoteSwiftPackageReference; repositoryURL = ${quote(p.url)}; requirement = { kind = upToNextMajorVersion; minimumVersion = ${quote(p.version)}; };`);
// Copie GoogleService-Info.plist (s'il existe) et ajoute l'URL Scheme REVERSED_CLIENT_ID pour Google.
const firebaseScript = [
  'PLIST="${SRCROOT}/iOS/GoogleService-Info.plist"',
  'if [ ! -f "$PLIST" ]; then',
  '  echo "warning: iOS/GoogleService-Info.plist absent : la connexion Firebase est désactivée (voir README)."',
  '  exit 0',
  'fi',
  'cp "$PLIST" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"',
  'INFO="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"',
  'REVERSED=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$PLIST" 2>/dev/null || true)',
  '/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$INFO" 2>/dev/null || true',
  'if [ -n "$REVERSED" ]; then',
  '  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" -c "Add :CFBundleURLTypes:0 dict" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $REVERSED" "$INFO"',
  'else',
  '  echo "warning: REVERSED_CLIENT_ID absent : active Google dans Firebase puis retelecharge GoogleService-Info.plist."',
  'fi',
  ''
].join(String.fromCharCode(10));
const commonFiles = ['Sources/RushCore/GameEngine.swift', 'Sources/RushCore/RewardsProgress.swift', 'Shared/GameModel.swift', 'Shared/RushTrack.swift', 'Shared/RewardsView.swift'];
const definitions = [
  {name:'PerfectRush', files:[...commonFiles, 'Sources/RushCore/AuthRules.swift', 'iOS/PerfectRushApp.swift', 'iOS/ContentView.swift', 'iOS/AuthManager.swift', 'iOS/AuthView.swift', 'iOS/PhoneGameView.swift'], sdk:'iphoneos', platforms:'iphoneos iphonesimulator', family:'1,2', bundle:'fr.theounniv.perfectrush', kind:'application', packages, firebase:true},
  {name:'PerfectRushWatch', files:[...commonFiles, 'Watch/PerfectRushWatchApp.swift', 'Watch/WatchGameView.swift'], sdk:'watchos', platforms:'watchos watchsimulator', family:'4', bundle:'fr.theounniv.perfectrush.watch', kind:'application'},
  {name:'PerfectRushTests', files:['Tests/RushCoreTests/GameEngineTests.swift', 'Tests/RushCoreTests/RewardsProgressTests.swift', 'Tests/RushCoreTests/AuthRulesTests.swift'], sdk:'iphoneos', platforms:'iphoneos iphonesimulator', family:'1,2', bundle:'fr.theounniv.perfectrush.tests', kind:'bundle.unit-test'},
  {name:'PerfectRushWidget', files:['Widgets/PerfectRushWidget.swift'], sdk:'iphoneos', platforms:'iphoneos iphonesimulator', family:'1,2', bundle:'fr.theounniv.perfectrush.widget', kind:'app-extension', parent:'PerfectRush'},
  {name:'PerfectRushWatchWidget', files:['Widgets/PerfectRushWidget.swift'], sdk:'watchos', platforms:'watchos watchsimulator', family:'4', bundle:'fr.theounniv.perfectrush.watch.widget', kind:'app-extension', parent:'PerfectRushWatch'}
];
const refs = new Map();
for (const file of new Set(definitions.flatMap(t=>t.files))) {
  const key = id(); refs.set(file,key);
  add(key, `isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ${quote(file)}; sourceTree = SOURCE_ROOT;`);
}
for (const t of definitions) {
  t.id = id(); t.product = id(); t.configs = id(); t.sources = id(); t.frameworks=id(); t.resources=id();
  const ext = t.kind === 'application' ? 'app' : t.kind === 'app-extension' ? 'appex' : 'xctest';
  const fileType = t.kind === 'application' ? 'wrapper.application' : t.kind === 'app-extension' ? 'wrapper.app-extension' : 'wrapper.cfbundle';
  add(t.product, `isa = PBXFileReference; explicitFileType = ${fileType}; includeInIndex = 0; path = ${t.name}.${ext}; sourceTree = BUILT_PRODUCTS_DIR;`);
  const builds = t.files.map(file=>{ const key=id(); add(key,`isa = PBXBuildFile; fileRef = ${refs.get(file)};`); return key; });
  add(t.sources, `isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ${list(builds)}; runOnlyForDeploymentPostprocessing = 0;`);
  // Chaque produit d'un paquet est relié (« linké ») à la cible dans la phase Frameworks.
  t.productDependencies = [];
  const linked = [];
  for (const p of t.packages || []) for (const product of p.products) {
    const dep = id(), file = id();
    add(dep, `isa = XCSwiftPackageProductDependency; package = ${p.key}; productName = ${product};`);
    add(file, `isa = PBXBuildFile; productRef = ${dep};`);
    t.productDependencies.push(dep); linked.push(file);
  }
  add(t.frameworks, `isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ${list(linked)}; runOnlyForDeploymentPostprocessing = 0;`);
  add(t.resources, `isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;`);
  if (t.firebase) {
    t.script = id();
    add(t.script, `isa = PBXShellScriptBuildPhase; alwaysOutOfDate = 1; buildActionMask = 2147483647; files = (); inputPaths = (${quote('$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)')},); name = ${quote('Firebase : configuration')}; outputPaths = (); runOnlyForDeploymentPostprocessing = 0; shellPath = /bin/sh; shellScript = ${quote(firebaseScript)}; showEnvVarsInLog = 0;`);
  }
  const configurations=[];
  for (const config of ['Debug','Release']) {
    const key=id(); configurations.push(key);
    const test=t.kind==='bundle.unit-test';
    const widget=t.kind==='app-extension';
    const settings={
      PRODUCT_NAME:'$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER:t.bundle,
      SDKROOT:t.sdk, SUPPORTED_PLATFORMS:t.platforms, TARGETED_DEVICE_FAMILY:t.family,
      SWIFT_VERSION:'5.0', GENERATE_INFOPLIST_FILE:'YES', CODE_SIGN_STYLE:'Automatic',
      MARKETING_VERSION:'1.0', CURRENT_PROJECT_VERSION:'1',
      SWIFT_OPTIMIZATION_LEVEL:config==='Debug'?'-Onone':'-O',
      SWIFT_ACTIVE_COMPILATION_CONDITIONS:config==='Debug'?'DEBUG':'',
      ENABLE_TESTABILITY:config==='Debug'?'YES':'NO',
      ...(t.sdk==='watchos'?{WATCHOS_DEPLOYMENT_TARGET:'10.0'}:{IPHONEOS_DEPLOYMENT_TARGET:'17.0'}),
      ...(t.name==='PerfectRushWatch'?{INFOPLIST_KEY_WKApplication:'YES',INFOPLIST_KEY_WKWatchOnly:'YES'}:{}),
      ...(test?{TEST_HOST:'$(BUILT_PRODUCTS_DIR)/PerfectRush.app/PerfectRush',BUNDLE_LOADER:'$(TEST_HOST)'}:{INFOPLIST_KEY_CFBundleDisplayName:'Perfect Rush'}),
      ...(widget?{INFOPLIST_FILE:'Widgets/Info.plist',APPLICATION_EXTENSION_API_ONLY:'YES',SKIP_INSTALL:'YES',LD_RUNPATH_SEARCH_PATHS:'$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'}:{}),
      ...(t.kind==='application'?{INFOPLIST_KEY_UILaunchScreen_Generation:'YES'}:{}),
      // Google Sign-In a besoin de -ObjC.
      ...(t.firebase?{OTHER_LDFLAGS:'$(inherited) -ObjC',ENABLE_USER_SCRIPT_SANDBOXING:'NO'}:{}),
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
// Chaque application contient son extension WidgetKit dans le dossier PlugIns.
for(const t of definitions) {
  const dependencies = t===test ? [dependency] : [];
  const phases = [t.sources,t.frameworks,t.resources,...(t.script?[t.script]:[])];
  for(const widget of definitions.filter(item=>item.parent===t.name)) {
    const widgetProxy=id(), widgetDependency=id(), embedFile=id(), embedPhase=id();
    add(widgetProxy,`isa = PBXContainerItemProxy; containerPortal = ${project}; proxyType = 1; remoteGlobalIDString = ${widget.id}; remoteInfo = ${widget.name};`);
    add(widgetDependency,`isa = PBXTargetDependency; target = ${widget.id}; targetProxy = ${widgetProxy};`);
    add(embedFile,`isa = PBXBuildFile; fileRef = ${widget.product}; settings = { ATTRIBUTES = (RemoveHeadersOnCopy,); };`);
    add(embedPhase,`isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = (${embedFile},); name = "Embed Widgets"; runOnlyForDeploymentPostprocessing = 0;`);
    dependencies.push(widgetDependency);
    phases.push(embedPhase);
  }
  add(t.id, `isa = PBXNativeTarget; buildConfigurationList = ${t.configs}; buildPhases = ${list(phases)}; buildRules = (); dependencies = ${list(dependencies)}; name = ${t.name}; productName = ${t.name}; productReference = ${t.product}; packageProductDependencies = ${list(t.productDependencies)}; productType = ${quote('com.apple.product-type.'+t.kind)};`);
}
add(main,`isa = PBXGroup; children = ${list([...refs.values(),products])}; sourceTree = "<group>";`);
add(products,`isa = PBXGroup; children = ${list(definitions.map(t=>t.product))}; name = Products; sourceTree = "<group>";`);
const pc=[];
for(const config of ['Debug','Release']) {const key=id();pc.push(key);add(key,`isa = XCBuildConfiguration; buildSettings = { CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; SWIFT_VERSION = 5.0; }; name = ${config};`);}
add(projectConfigs,`isa = XCConfigurationList; buildConfigurations = ${list(pc)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;`);
add(project,`isa = PBXProject; attributes = { BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1500; TargetAttributes = { ${definitions.map(t=>`${t.id} = { CreatedOnToolsVersion = 15.0; ${t===test?`TestTargetID = ${phone.id};`:''} };`).join(' ')} }; }; buildConfigurationList = ${projectConfigs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = fr; hasScannedForEncodings = 0; knownRegions = (fr,en,Base); mainGroup = ${main}; packageReferences = ${list(packages.map(p=>p.key))}; productRefGroup = ${products}; projectDirPath = ""; projectRoot = ""; targets = ${list(definitions.map(t=>t.id))};`);
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
