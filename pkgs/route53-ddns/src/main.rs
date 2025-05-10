use std::error::Error;
use std::net::IpAddr;

use aws_config::BehaviorVersion;
use aws_sdk_route53::operation::list_resource_record_sets::ListResourceRecordSetsOutput;
use aws_sdk_route53::types::{Change, ChangeAction, ResourceRecord, ResourceRecordSet};
use aws_sdk_route53::types::{ChangeBatch, RrType};
use clap::Parser;

#[derive(clap::ValueEnum, Copy, Clone, Eq, PartialEq, Debug)]
enum IpType {
    Lan,
    Public,
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short = 'z', long)]
    hosted_zone_id: String,

    #[arg(short, long)]
    domain: String,

    #[arg(short, long)]
    ip: IpType,

    #[arg(long, default_value_t = 300)]
    ttl: u32,
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn Error>> {
    let mut args = Args::parse();
    if !args.domain.ends_with('.') {
        args.domain.push('.');
    }
    dbg!(&args);

    let ip = match args.ip {
        IpType::Lan => local_ip_address::local_ip()?,
        IpType::Public => get_public_ip().await?,
    };
    println!("Using IP: {}", ip);

    let config = aws_config::load_defaults(BehaviorVersion::latest()).await;
    let client = aws_sdk_route53::Client::new(&config);

    let updated = Record {
        name: &args.domain,
        ty: RrType::A,
        value: &ip.to_string(),
        ttl: args.ttl,
    };
    let record_sets = list_record_sets(&client, &args.hosted_zone_id, &updated).await?;

    let current = extract_record(&record_sets, &args.domain, "A");

    if Some(&updated) == current.as_ref() {
        println!("No update required");
        return Ok(());
    }

    println!("Updating record {current:?} -> {updated:?}");
    update(client, &args.hosted_zone_id, updated).await?;

    Ok(())
}

async fn update(
    client: aws_sdk_route53::Client,
    hosted_zone_id: &str,
    record: Record<'_>,
) -> Result<(), Box<dyn Error>> {
    let record_set = ResourceRecordSet::builder()
        .name(record.name)
        .r#type(RrType::A)
        .ttl(record.ttl as i64)
        .resource_records(ResourceRecord::builder().value(record.value).build()?)
        .build()?;
    let change = Change::builder()
        .action(ChangeAction::Upsert)
        .resource_record_set(record_set)
        .build()?;
    let result = client
        .change_resource_record_sets()
        .hosted_zone_id(hosted_zone_id)
        .change_batch(
            ChangeBatch::builder()
                .comment("DDNS Update")
                .changes(change)
                .build()?,
        )
        .send()
        .await?;
    dbg!(result);
    Ok(())
}

async fn get_public_ip() -> Result<IpAddr, Box<dyn Error>> {
    let https = hyper_rustls::HttpsConnectorBuilder::new()
        .with_native_roots()
        .https_only()
        .enable_all_versions()
        .build();
    let client: hyper::Client<_, hyper::Body> = hyper::Client::builder().build(https);

    let resp = client
        .get("https://checkip.amazonaws.com/".parse()?)
        .await?;

    let body = hyper::body::to_bytes(resp.into_body()).await?;
    let ip = std::str::from_utf8(&body)?.trim();
    Ok(ip.parse()?)
}

async fn list_record_sets(
    client: &aws_sdk_route53::Client,
    hosted_zone_id: &str,
    start: &Record<'_>,
) -> Result<ListResourceRecordSetsOutput, Box<dyn Error>> {
    Ok(client
        .list_resource_record_sets()
        .hosted_zone_id(hosted_zone_id)
        .start_record_name(start.name)
        .start_record_type(start.ty.clone())
        .max_items(1)
        .send()
        .await?)
}

fn extract_record<'a>(
    output: &'a ListResourceRecordSetsOutput,
    name: &str,
    ty: &str,
) -> Option<Record<'a>> {
    let [ref records] = output.resource_record_sets[..] else {
        return None;
    };
    let [ref record] = records.resource_records.as_ref()?[..] else {
        return None;
    };
    if records.name == name && records.r#type.as_ref() == ty {
        Some(Record {
            name: records.name.as_ref(),
            ty: records.r#type.clone(),
            value: record.value.as_ref(),
            ttl: records
                .ttl
                .and_then(|ttl| u32::try_from(ttl).ok())
                .unwrap_or(0),
        })
    } else {
        None
    }
}

#[derive(Eq, PartialEq, Debug)]
struct Record<'a> {
    name: &'a str,
    ty: RrType,
    value: &'a str,
    ttl: u32,
}
