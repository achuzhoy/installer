package bootstrap

import (
	"github.com/openshift/installer/pkg/types"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"os"
	"strconv"
)

// bootstrapTemplateData is the data to use to replace values in bootstrap
// template files.
type singleNodeBootstrapInPlaceTemplateData struct {
	BootstrapInPlace  bool
	SkipReboot        bool
	CoreosInstallArgs string
	InstallationDisk   string
}

// GetBootstrapInPlaceConfig generates the config for the BootstrapInPlace.
func GetSingleNodeBootstrapInPlaceConfig(installConfig *types.InstallConfig) (*singleNodeBootstrapInPlaceTemplateData, error) {
	bootstrapInPlace, err := isBootstrapInPlace(installConfig)
	if err != nil {
		return nil, err
	}
	if bootstrapInPlace {
		skipReboot, err := getSkipReboot()
		if err != nil {
			return nil, err
		}

		return &singleNodeBootstrapInPlaceTemplateData{
			BootstrapInPlace:  bootstrapInPlace,
			SkipReboot:        skipReboot,
			InstallationDisk:   getInstallationDisk(),
			CoreosInstallArgs: getCoreosInsallArgs(),
		}, nil
	}
	return &singleNodeBootstrapInPlaceTemplateData{}, nil
}

// isBootstrapInPlace checks for bootstrap in place env and validate the number of control plane replica is one
func isBootstrapInPlace(installConfig *types.InstallConfig) (bootstrapInPlace bool, err error) {
	if bootstrapInPlaceEnv := os.Getenv("OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE"); bootstrapInPlaceEnv != "" {
		bootstrapInPlace, err = strconv.ParseBool(bootstrapInPlaceEnv)
		if err != nil {
			return bootstrapInPlace, err
		}
		if bootstrapInPlace {
			if *installConfig.ControlPlane.Replicas != 1 {
				return bootstrapInPlace, errors.Wrapf(err, "Found OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE env but control plane replica is not 1")
			}
			logrus.Warnf("Creating bootstrap in place configuration")
		}
	}
	return bootstrapInPlace, err
}

// getSkipReboot checks for bootstrap in place skipReboot env
func getSkipReboot() (skipReboot bool, err error) {
	if skipRebootEnv := os.Getenv("OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_SKIP_REBOOT"); skipRebootEnv != "" {
		skipReboot, err = strconv.ParseBool(skipRebootEnv)
		if err != nil {
			return skipReboot, err
		}
		if skipReboot {
			logrus.Warnf("Setting skip reboot to: %t", skipReboot)
		}
	}
	return skipReboot, err
}

// getInstallationDisk checks for bootstrap in place installationDisk env
func getInstallationDisk() string {
	insatllationDiskEnv := os.Getenv("OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_INSTALLATION_DISK")
	if insatllationDiskEnv != "" {
		logrus.Warnf("Setting installation disk to: %s", insatllationDiskEnv)
	}
	return insatllationDiskEnv
}

// getCoreosInsallArgs checks for bootstrap in place installationDisk env
func getCoreosInsallArgs() string {
	coreosInstallEnv := os.Getenv("OPENSHIFT_INSTALL_EXPERIMENTAL_BOOTSTRAP_IN_PLACE_COREOS_INSTALL_ARGS")
	if coreosInstallEnv != "" {
		logrus.Warnf("Setting coreos-install args: %s", coreosInstallEnv)
	}
	return coreosInstallEnv
}
