#!groovy

// Jenkinsfile for compiling, testing, and packaging
// Requires CMake plugin from https://github.com/davidjsherman/aseba-jenkins.git in global library.

pipeline {
	agent any // use any available Jenkins agent

	// Trigger the build
	triggers {
		// Poll GitHub every two hours, in case webhooks aren't used
		pollSCM('H */2 * * *')
	}

	// Everything will be built in the build/ directory.
	// Everything will be installed in the dist/ directory.
	stages {
		stage('Prepare') {
			steps {
				checkout scm
			}
		}
		stage('Compile') {
			parallel {
				stage("Compile on linux") {
					agent {
						label 'linux'
					}
					steps {
						CMake([label: 'linux'])
						stash includes: 'dist/**', name: 'dist-linux'
						stash includes: 'build/**', name: 'build-linux'
					}
				}
				stage("Compile on macos") {
					agent {
						label 'macos'
					}
					steps {
						CMake([label: 'macos'])
						stash includes: 'dist/**', name: 'dist-macos'
					}
				}
				stage("Compile on windows") {
					agent {
						label 'windows'
					}
					steps {
						CMake([label: 'windows'])
						stash includes: 'dist/**', name: 'dist-windows'
					}
				}
			}
		}
		//stage('Test') {
		//	parallel {
		//		stage("Test on linux") {
		//			agent {
		//				label 'linux'
		//			}
		//			steps {
		//				unstash 'build-linux'
		//				dir('build/linux') {
		//					sh 'LANG=C ctest'
		//				}
		//			}
		//		}
		//	}
		//}
		stage('Archive') {
			steps {
				unstash 'dist-linux'
				unstash 'dist-macos'
				unstash 'dist-windows'
				archiveArtifacts artifacts: 'dist/**', fingerprint: true, onlyIfSuccessful: true
			}
		}
	}
}