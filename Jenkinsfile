#!groovy

// Jenkinsfile for compiling, testing, and packaging

// Our build matrix. The keys are the operating system labels and the values
// are lists of tool labels.
buildMatrix = [
    // One release and debug build per supported OS.
    ['linux', [
        builds: ['release'],
        tools: ['gcc'],
    ]],
    ['macos', [
        builds: ['debug', 'release'],
        tools: ['clang'],
    ]],
//    ['windows', [
//        builds: ['debug', 'release'],
//        tools: ['msvc'],
//    ]],
]

// cmake build function
def cmakeSteps(buildType, cmakeArgs, buildId) {
    def installDir = "$WORKSPACE/$buildId"
    dir('dpmaster-sources') {
        // Configure and build.
        cmakeBuild([
            buildDir: 'build',
            buildType: buildType,
            cmakeArgs: (cmakeArgs + [
              "CMAKE_INSTALL_PREFIX=\"$installDir\"",
            ]).collect { x -> '-D' + x }.join(' '),
            installation: 'cmake in search path',
            sourceDir: '.',
            steps: [[
                args: '--target install',
                withCmake: true,
            ]],
        ])
        // Run unit tests.
        //ctest([
        //    arguments: '--output-on-failure',
        //    installation: 'cmake in search path',
        //    workingDir: 'build',
        //])
    }
    // Only generate artifacts for the master branch.
    if (PrettyJobBaseName == 'master') {
      zip([
          archive: true,
          dir: buildId,
          zipFile: "${buildId}.zip",
      ])
    }
}

// Builds `name` with CMake and runs the unit tests.
def buildSteps(buildType, cmakeArgs, buildId) {
    echo "build stage: $STAGE_NAME"
    deleteDir()
    dir(buildId) {
        // Create directory.
    }
    unstash('dpmaster-sources')
    if (STAGE_NAME.contains('Windows')) {
        echo "Windows build on $NODE_NAME"
        withEnv(['PATH=C:\\Windows\\System32;C:\\Program Files\\CMake\\bin;C:\\Program Files\\Git\\cmd;C:\\Program Files\\Git\\bin']) {
            cmakeSteps(buildType, cmakeArgs, buildId)
        }
    } else {
        echo "Unix build on $NODE_NAME"
        withEnv(["label_exp=" + STAGE_NAME.toLowerCase()) {
            cmakeSteps(buildType, cmakeArgs, buildId)
        }
    }
}

// Builds a stage for given builds. Results in a parallel stage `if builds.size() > 1`.
def makeBuildStages(matrixIndex, builds, lblExpr, settings) {
    builds.collectEntries { buildType ->
        def id = "$matrixIndex $lblExpr: $buildType"
        [
            (id):
            {
                node(lblExpr) {
                    stage(id) {
                      try {
                          def buildId = "$lblExpr && $buildType"
                          withEnv(buildEnvironments[lblExpr] ?: []) {
                              buildSteps(buildType, settings['cmakeArgs'], buildId)
                              (settings['extraSteps'] ?: []).each { fun -> "$fun"() }
                          }
                      } finally {
                          cleanWs()
                      }
                    }
                }
            }
        ]
    }
}

pipeline {
    agent none
    environment {
        PrettyJobBaseName = env.JOB_BASE_NAME.replace('%2F', '/')
        PrettyJobName = "build #${env.BUILD_NUMBER} for $PrettyJobBaseName"
    }

	// Trigger the build
	triggers {
		// Poll GitHub every two hours, in case webhooks aren't used
		pollSCM('H */2 * * *')
	}

	stages {
		// Checkout Git source
		stage('Git Checkout') {
			steps {
				deleteDir()
				dir('dpmaster-sources') {
					checkout scm
				}
				stash includes: 'dpmaster-sources/**', name: 'dpmaster-sources'
			}
		}
		// Start builds
		stage('Builds') {
            steps {
                script {
                    // Create stages for building everything in our build matrix in parallel.
                    def xs = [:]
                    buildMatrix.eachWithIndex { entry, index ->
                        def (os, settings) = entry
                        settings['tools'].eachWithIndex { tool, toolIndex ->
                            def matrixIndex = "[$index:$toolIndex]"
                            def builds = settings['builds']
                            def labelExpr = "$os && $tool"
                            xs << makeBuildStages(matrixIndex, builds, labelExpr, settings)
                        }
                    }
                    parallel xs
                }
            }
        }
    }
}