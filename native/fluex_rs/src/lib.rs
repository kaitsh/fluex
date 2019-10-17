#[macro_use]
extern crate rustler;
extern crate fluent;
extern crate unic_langid;

use fluent::{FluentArgs, FluentBundle, FluentResource, FluentValue};
use rustler::resource::ResourceArc;
use rustler::types::map::MapIterator;
use rustler::{Encoder, Env, Error, Term};
use unic_langid::LanguageIdentifier;

mod atoms {
    rustler_atoms! {
        atom ok;
        //atom error;
        atom __true__ = "true";
        atom __false__ = "false";
    }
}

struct FluexBundle(FluentBundle<FluentResource>);

rustler::rustler_export_nifs! {
    "Elixir.Fluex.FluentRS",
    [
        ("new", 2, new),
        ("has_message?", 2, has_message),
        ("format_pattern", 3, format_pattern)
    ],
    Some(on_load)
}

fn on_load(env: Env, _info: Term) -> bool {
    rustler::resource_struct_init!(FluexBundle, env);
    true
}

fn new<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let locale: &str = args[0].decode()?;
    let ftl_string: String = args[1].decode()?;

    let resource = FluentResource::try_new(ftl_string).expect("Failed to parse an FTL string.");

    let lang_id: LanguageIdentifier = locale.parse().expect("Parsing failed.");

    let mut bundle = FluentBundle::new(&[lang_id]);
    bundle
        .add_resource(resource)
        .expect("Failed to add FTL resources to the bundle.");

    let res = ResourceArc::new(FluexBundle(bundle));

    Ok((res).encode(env))
}

fn has_message<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let res: ResourceArc<FluexBundle> = args[0].decode()?;
    let id: &str = args[1].decode()?;

    match res.0.has_message(id) {
        true => Ok((atoms::__true__()).encode(env)),
        false => Ok((atoms::__false__()).encode(env)),
    }
}

fn format_pattern<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let res: ResourceArc<FluexBundle> = args[0].decode()?;
    let id: &str = args[1].decode()?;
    let iter: MapIterator = args[2].decode()?;

    let mut attrs = FluentArgs::new();
    for (key, value) in iter {
        let key_string = key.decode::<&str>()?;
        let val_string = value.decode::<&str>()?;
        attrs.insert(key_string, FluentValue::from(val_string));
    }

    let msg = res.0.get_message(id).expect("Message doesn't exist.");
    let mut errors = vec![];
    let pattern = msg.value.expect("Message has no value.");
    let value = res.0.format_pattern(&pattern, Some(&attrs), &mut errors);

    Ok((value).encode(env))
}
