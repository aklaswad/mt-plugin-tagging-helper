# $Id$

package MT::Plugin::TaggingHelper;

use strict;
use MT::Template::Context;
use MT::Plugin;
@MT::Plugin::TaggingHelper::ISA = qw(MT::Plugin);

use vars qw($PLUGIN_NAME $VERSION);
$PLUGIN_NAME = 'TaggingHelper';
$VERSION = '0.2';

use MT;
my $plugin = new MT::Plugin::TaggingHelper({
    name => $PLUGIN_NAME,
    version => $VERSION,
    description => "<MT_TRANS phrase='description of TaggingHelper'>",
    doc_link => 'http://blog.aklaswad.com/mtplugins/tagginghelper/',
    author_name => 'akira sawada',
    author_link => 'http://blog.aklaswad.com/',
    l10n_class => 'TaggingHelper::L10N',
});

MT->add_plugin($plugin);

my $mt_version = MT->version_number;
if ($mt_version =~ /^4/){
    MT->add_callback('template_param.edit_entry', 9, $plugin, \&hdlr_mt4_param);
}
else {
    MT->add_callback('MT::App::CMS::AppTemplateSource.edit_entry', 9, $plugin, \&hdlr_mt3_source);
}

sub _build_html {
    my ($staticwebpath) = @_;
    my $html = <<'EOT';
<style type="text/css">

#tagging_helper_container {
    cursor: Default;
    width: 100%;
    text-align: right;
}

#tagging_helper_block {
    cursor: Default;
    text-align: left;
    margin: 10px 0;
    line-height: 1.8em;
}

.taghelper_tag {
    cursor: Default;
    color: #61889b;
    margin: 0 5px;
}

.taghelper_tag:hover {
    cursor: Pointer;
    color: #000;
}

.taghelper_tag_selected {
    cursor: Default;
    color: #41687b;
    margin: 0 5px;
    background-color: #def;
}

.taghelper_tag_selected:hover {
    cursor: Pointer;
    color: #000;
}

.taghelper_opener {
    cursor: Default;
    color: #61889b;
    background-image: url(__staticwebpathimages/status_icons/create.gif);
    background-repeat: no-repeat;
    background-position: left center;
    padding-left: 11px;
}

.taghelper_opener:hover {
    cursor: Pointer;
    color: #a2ad00;
}


</style>

<script type="text/javascript">
var taghelper_ready = 0;
var taghelper_display = 0;

function taghelper_close() {
    document.getElementById('taghelper_close').style.display = 'none';
    document.getElementById('tagging_helper_block').style.display = 'none';
}

function compareStrAscend(a, b){
    return a.localeCompare(b);
}

function quotemeta (string) {
    return string.replace(/(\W)/, "\\$1");
}

function taghelper_open(mode) {
    document.getElementById('taghelper_close').style.display = 'inline';
    var block = document.getElementById('tagging_helper_block');
    if (block.style.display == 'none') {
        block.style.display = 'block';
    }

    var tagary = new Array();
    if (mode == 'all') {
        for (var tag in tags ){
            tagary.push(tag);
        }
    }
    else {
        var body = document.getElementById('editor-input-content').value + document.getElementById('editor-input-extended').value;
        for (var tag in tags ) {
            var exp = new RegExp(quotemeta(tag));
            if (exp.test(body)) {
                tagary.push(tag);
            }
        }
    }
    tagary.sort(compareStrAscend);

    var v = document.getElementById('tags').value;
    var taglist = '';
    for (var i=0; i< tagary.length; i++) {
        var tag = tagary[i];
        var exp = new RegExp("^(.*, ?)?" + tag + "( ?\,.*)?$");
        if (exp.test(v)) {
            taglist += '<span onclick="taghelper_action(\'' + tag + '\')" class="taghelper_tag_selected", id="taghelper_tag_' + tag + '">' + tag + ' </span>';
        }
        else {
            taglist += '<span onclick="taghelper_action(\'' + tag + '\')" class="taghelper_tag", id="taghelper_tag_' + tag + '">' + tag + ' </span>';
        }
    }
    block.innerHTML = taglist;    
        
    taghelper_ready = 1;
}

function taghelper_action(s) {
    var a = document.getElementById('taghelper_tag_' + s);
    
    var v = document.getElementById('tags').value;
    var exp = new RegExp("^(.*, ?)?" + s + "( ?\,.*)?$");
    if (exp.test(v)) {
        v = v.replace(exp, "$1$2");
        if (tag_delim == ',') {
            v = v.replace(/ *, *, */g, ', ');
        }
        else {
            v = v.replace(/  +/g, ' ');
        }
        a.className = 'taghelper_tag';
    }
    else {
        v += (tag_delim == ',' ? ', ' : ' ') + s;
        a.className = 'taghelper_tag_selected';
    }
    v = v.replace(/^[ \,]+/, '');
    v = v.replace(/[ \,]+$/, '');
    document.getElementById('tags').value = v;
}

</script>
<div id="tagging_helper_container">
<span id="taghelper_all" onclick="taghelper_open('all')" class="taghelper_opener"><MT_TRANS phrase="old tags"></span>
<span id="taghelper_match" onclick="taghelper_open('match')" class="taghelper_opener"><MT_TRANS phrase="match tags"></span>
<span id="taghelper_close" onclick="taghelper_close()" class="taghelper_opener" style="display: none;"><MT_TRANS phrase="close"></span>
<div id="tagging_helper_block" style="display: none;"></div>
</div>
EOT
    $html =~ s/__staticwebpath/$staticwebpath/;
    return $plugin->translate_templatized($html);
}

sub hdlr_mt3_source {
    my ($eh, $app, $tmpl) = @_;
    my $staticwebpath = $app->config('StaticWebPath');
    my $html = _build_html($staticwebpath); 
    my $pattern = quotemeta(<<'EOT');
<input name="tags" id="tags" tabindex="7" value="<TMPL_VAR NAME=TAGS ESCAPE=HTML>" onchange="setDirty()" />
</div>
EOT
    $$tmpl =~ s!($pattern)!$1$html!;
}

sub hdlr_mt4_param {
    my ($eh, $app, $param, $tmpl) = @_;
    my $staticwebpath = $app->config('StaticWebPath');
    my $html = _build_html($staticwebpath); 
    die 'something wrong...' unless UNIVERSAL::isa($tmpl, 'MT::Template');
 
    my $host_node = $tmpl->getElementById('tags')
        or die 'cannot get useful-links block';

    $host_node->innerHTML($host_node->innerHTML . $html);
    1;
}

1;

