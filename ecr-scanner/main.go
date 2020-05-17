package main

import (
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"path"
	"strings"

	"gopkg.in/yaml.v3"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecr"
)

type ScanConfig struct {
	Severity []string `yaml:"severity"`
	Excluded []string `yaml:"excluded"`
}

func main() {
	ecrUrl, err := url.Parse("https://" + os.Args[1])
	if err != nil {
		log.Fatal(err)
	}

	hostPart := strings.Split(ecrUrl.Host, ".")
	if len(hostPart) != 6 {
		log.Fatalln("Unknown host portion of ECR URL:", ecrUrl.Host)
	}
	ecrAccount := hostPart[0]
	ecrRegion := hostPart[3]

	imagePart := strings.Split(ecrUrl.Path, ":")
	if len(imagePart) != 2 {
		log.Fatal("Unable to detect image:tag in supplied URL")
	}
	image := strings.TrimPrefix(imagePart[0], "/")
	tag := imagePart[1]

	// AWS Session
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		Config:            *aws.NewConfig().WithRegion(ecrRegion),
		SharedConfigState: session.SharedConfigEnable,
	}))

	// ECR Client
	ecrclient := ecr.New(sess)

	input := &ecr.DescribeImageScanFindingsInput{
		RegistryId:     aws.String(ecrAccount),
		RepositoryName: aws.String(image),
		ImageId: &ecr.ImageIdentifier{
			ImageTag: aws.String(tag),
		},
	}

	var findings []*ecr.ImageScanFinding
	for {
		resp, err := ecrclient.DescribeImageScanFindings(input)
		if err != nil {
			log.Fatal(err)
		}

		findings = append(findings, resp.ImageScanFindings.Findings...)

		if resp.NextToken == nil {
			break
		}

		input.NextToken = resp.NextToken
	}

	pwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	yamlFile, err := ioutil.ReadFile(path.Join(pwd, ".ecr-scanner.yml"))
	if err != nil {
		log.Fatal(err)
	}

	var scanConfig ScanConfig
	err = yaml.Unmarshal(yamlFile, &scanConfig)
	if err != nil {
		log.Fatal(err)
	}

	var matching []*ecr.ImageScanFinding
	for _, finding := range findings {
		for _, excluded := range scanConfig.Excluded {
			if *finding.Name == excluded {
				log.Println("Skipping", excluded)
				continue
			}
		}
		for _, severity := range scanConfig.Severity {
			if *finding.Severity == severity {
				matching = append(matching, finding)
				continue
			}
		}
	}

	if len(matching) > 0 {
		log.Println(matching)
		log.Fatal("ERROR: Fatal findings detected")
	}

	log.Println("No findings detected!")
}
