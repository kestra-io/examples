use std::error::Error;
use std::fs::File;
use std::process;

use csv;
use rand::Rng;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
struct Record {
    id: u64,
    value: u64,
}

fn main() -> Result<(), Box<dyn Error>> {
    let n = 10;
    let mut rng = rand::thread_rng();

    // Generate random data
    let mut records = Vec::new();
    for _ in 0..n {
        records.push(Record {
            id: rng.gen_range(1..n+1),
            value: rng.gen_range(1..100),
        });
    }

    // Write to a CSV file
    let file = File::create("input.csv")?;
    let mut wtr = csv::Writer::from_writer(file);
    for record in &records {
        wtr.serialize(record)?;
    }
    wtr.flush()?;

    // Read the created CSV file
    let file = File::open("input.csv")?;
    let mut rdr = csv::Reader::from_reader(file);

    // Transform the data (here we simply add 1 to each value)
    let mut transformed_records = Vec::new();
    for result in rdr.deserialize() {
        let mut record: Record = result?;
        record.value += 1;
        transformed_records.push(record);
    }

    // Write transformed data to another CSV file
    let file = File::create("output.csv")?;
    let mut wtr = csv::Writer::from_writer(file);
    for record in &transformed_records {
        wtr.serialize(record)?;
    }
    wtr.flush()?;

    Ok(())
}
