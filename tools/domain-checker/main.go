package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/route53domains"
)

func main() {
	ctx := context.Background()

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("us-east-1"))
	if err != nil {
		log.Fatal(err)
	}

	client := route53domains.NewFromConfig(cfg)

	result, err := client.CheckDomainAvailability(ctx, &route53domains.CheckDomainAvailabilityInput{
		DomainName: aws.String("example.com"),
	})
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(result.Availability)
}
