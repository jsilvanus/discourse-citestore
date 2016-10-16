import { registerOption } from 'pretty-text/pretty-text';

registerOption((siteSettings, opts) => {
  opts.features['citestore-resolver'] = true;
});

function yes_it_exists(handle, locus) {
  return false;
}

function replace_from_store (handle, locus) {
  return "TEST TEST TEST";
}

function citestore_resolver (text) {
    // 1. Find brackets that have [xxx yyy]
    // 2. Match xxx to existing handles and yyy to existing locus
    // 3. Replace bracket with text
    return text;
}

export function setup(helper) {
  helper.addPreProcessor(piratize);
}
