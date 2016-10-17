import { registerOption } from 'pretty-text/pretty-text';
import { ajax } from 'discourse/lib/ajax'

registerOption((siteSettings, opts) => {
  opts.features['citestore-resolver'] = true;
});

function citestore_resolver (text) {
  handles = ajax('/citestore/storage', { type: "GET" } );

  function get_locus(handle, locus) {
    return ajax('/citestore/', {
      type: "GET",
      data: { handle: handle, locus: locus }
  }

  for each (var handle in handles) {
    var re = new RegExp("\\["+handle+" (\\w)\\]","gi");

    function replacer(match, p1, offset, string) {
      return get_locus(handle, p1);
    }
    text.replace(re, replacer);
  }
  return text;
}

export function setup(helper) {
  helper.addPreProcessor(piratize);
}

