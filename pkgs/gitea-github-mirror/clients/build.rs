use progenitor::{GenerationSettings, InterfaceStyle};

fn generate(name: &str) {
    let env = format!("{}_OPENAPI", name.to_uppercase());
    println!("cargo:rerun-if-env-changed={env}");
    let src = &std::env::var(env).unwrap();
    let file = std::fs::File::open(src).unwrap();
    let spec = serde_json::from_reader(file).unwrap();
    let mut generator = progenitor::Generator::new(
        GenerationSettings::default().with_interface(InterfaceStyle::Builder),
    );

    let tokens = generator.generate_tokens(&spec).unwrap();
    let ast = syn::parse2(tokens).unwrap();
    let content = prettyplease::unparse(&ast);

    let mut out_file = std::path::Path::new(&std::env::var("OUT_DIR").unwrap()).to_path_buf();
    out_file.push(format!("{name}.rs"));

    std::fs::write(out_file, content).unwrap();
}

fn main() {
    generate("gitea");
    generate("github");
}
