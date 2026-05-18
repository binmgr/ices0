pipeline {
    agent { label 'ubuntu-latest' }

    options {
        disableConcurrentBuilds()
        timeout(time: 120, unit: 'MINUTES')
    }

    environment {
        BUILD_IMAGE = 'ghcr.io/binmgr/ices0:build'
    }

    stages {
        stage('Build Linux') {
            parallel {
                stage('amd64') {
                    steps {
                        sh '''
                            mkdir -p output-amd64
                            docker run --rm --name ices0-build-amd64-$BUILD_NUMBER \
                                -v "$WORKSPACE/output-amd64:/output" \
                                "$BUILD_IMAGE" build-ices0 amd64
                        '''
                        archiveArtifacts artifacts: 'output-amd64/ices0-linux-amd64', fingerprint: true
                    }
                }
                stage('arm64') {
                    steps {
                        sh '''
                            mkdir -p output-arm64
                            docker run --rm --name ices0-build-arm64-$BUILD_NUMBER \
                                -v "$WORKSPACE/output-arm64:/output" \
                                "$BUILD_IMAGE" build-ices0 arm64
                        '''
                        archiveArtifacts artifacts: 'output-arm64/ices0-linux-arm64', fingerprint: true
                    }
                }
            }
        }

        stage('Security') {
            parallel {
                stage('Secret scan') {
                    steps {
                        sh '''
                            docker run --rm --name trufflehog-$BUILD_NUMBER \
                                -v "$WORKSPACE:/repo" \
                                trufflesecurity/trufflehog:latest \
                                git file:///repo --since-commit HEAD~1 --only-verified --fail
                        '''
                    }
                }
                stage('Workflow policy') {
                    steps {
                        sh '''
                            bad=0
                            for file in .github/workflows/*.yml .gitea/workflows/*.yml .forgejo/workflows/*.yml; do
                                [ -f "$file" ] || continue
                                while IFS= read -r line; do
                                    if printf '%s' "$line" | grep -qE '^\\s+uses:\\s+[a-zA-Z0-9_.-]+/[a-zA-Z0-9_./-]+@'; then
                                        sha=$(printf '%s' "$line" | sed -E 's/.*@([^ #]+).*/\\1/')
                                        if ! printf '%s' "$sha" | grep -qxE '[0-9a-f]{40}'; then
                                            echo "Unpinned action in ${file}: $(printf '%s' "$line" | xargs)"
                                            bad=1
                                        fi
                                    fi
                                done < "$file"
                                if grep -qE '^\\s*pull_request_target\\s*:' "$file"; then
                                    echo "Dangerous trigger pull_request_target in ${file}"
                                    bad=1
                                fi
                            done
                            [ "$bad" -eq 0 ] || exit 1
                        '''
                    }
                }
                stage('Container scan') {
                    steps {
                        sh '''
                            curl -qLSsf https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
                                | sh -s -- -b /usr/local/bin
                            trivy image --exit-code 1 --ignore-unfixed --severity CRITICAL,HIGH \
                                ghcr.io/binmgr/ices0:latest
                        '''
                    }
                }
            }
        }

        stage('Release') {
            when { tag 'v*' }
            steps {
                sh '''
                    mkdir -p release
                    cp output-amd64/ices0-linux-amd64 release/ 2>/dev/null || true
                    cp output-arm64/ices0-linux-arm64 release/ 2>/dev/null || true
                    chmod +x release/*
                    cd release && sha256sum * > checksums.txt
                '''
                archiveArtifacts artifacts: 'release/*', fingerprint: true
            }
        }
    }

    post {
        always {
            sh 'docker rmi ghcr.io/binmgr/ices0:build 2>/dev/null || true'
            cleanWs()
        }
    }
}
