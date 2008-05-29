package MT::Plugin::TaggingHelper;

use strict;
use MT::Template::Context;
use MT::Plugin;
@MT::Plugin::TaggingHelper::ISA = qw(MT::Plugin);

use vars qw($PLUGIN_NAME $VERSION);
$PLUGIN_NAME = 'TaggingHelper';
$VERSION = '0.3';

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

.tagging_helper_table {
    cursor: Default;
    text-align: left;
    margin: 10px 0;
    line-height: 1.8em;
}

.taghelper_tag {
    cursor: Default;
    color: #41687b;
    margin: 0 5px;
}

.taghelper_tag:hover {
    cursor: Pointer;
    color: #246;
    text-decoration: underline;
}

.taghelper_tag_selected {
    cursor: Default;
    color: #41687b;
    background-color: #bcd;
    margin: 0 5px;
}

.taghelper_tag_selected:hover {
    cursor: Pointer;
    color: #246;
    text-decoration: underline;
}

.taghelper_command {
    cursor: Default;
    color: #61889b;
    margin-left: 11px;
}

.taghelper_command:hover {
    cursor: Pointer;
    color: #a2ad00;
}

</style>

<script type="text/javascript">
// simple js syntax, because MT3.3 dosen't have js library.
// just use RegExp.escape; which appear both MT3.3 and MT4. 

var TaggingHelper = new Object();

TaggingHelper.close = function() {
    document.getElementById('tagging_helper_block').style.display = 'none';
}

TaggingHelper.compareStrAscend = function (a, b){
    return a.localeCompare(b);
}

TaggingHelper.compareByCount = function (a, b){
    return tags[b] - tags[a];
}

__getbody

TaggingHelper.open = function (mode) {
    var block = document.getElementById('tagging_helper_block');
    if (block.style.display == 'none') {
        block.style.display = 'block';
    }

    var tagary = new Array();
    if (mode == 'abc' || mode == 'count') {
        for (var tag in tags ){
            tagary.push(tag);
        }
    }
    else {
        var body = this.getBody();
        for (var tag in tags ) {
            var exp = new RegExp(RegExp.escape(tag));
            if (exp.test(body)) {
                tagary.push(tag);
            }
        }
    }
    if (mode == 'count')
        tagary.sort(this.compareByCount);
    else
        tagary.sort(this.compareStrAscend);

    var v = document.getElementById('tags').value;
    var taglist = '';
    var table = document.createElement('div');
    table.className = 'taghelper-table';
    for (var i=0; i< tagary.length; i++) {
        var tag = tagary[i];
        var e = document.createElement('span');
        e.onclick   = TaggingHelper.action;
        e.th_tag    = tag;
        e.appendChild( document.createTextNode(tag) );
        var exp = new RegExp("^(.*, ?)?" + RegExp.escape(tag) + "( ?\,.*)?$");
        e.className = (exp.test(v)) ? 'taghelper_tag_selected' : 'taghelper_tag';
        table.appendChild(e);
        table.appendChild( document.createTextNode(' ') );
    }

    while (block.childNodes.length) block.removeChild(block.childNodes.item(0));
    block.appendChild(table);
}

TaggingHelper.action = function (evt) {
    // IE-Firefox compatible
    var e = evt || window.event;
    var a = e.target || e.srcElement;
    var s = a.th_tag;
    
    var v = document.getElementById('tags').value;
    var exp = new RegExp("^(.*, ?)?" + RegExp.escape(s) + "( ?\,.*)?$");
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
    <span id="taghelper_abc" onclick="TaggingHelper.open('abc')" class="taghelper_command"><MT_TRANS phrase="alphabetical"></span>
    <span id="taghelper_count" onclick="TaggingHelper.open('count')" class="taghelper_command"><MT_TRANS phrase="frequency"></span>
    <span id="taghelper_match" onclick="TaggingHelper.open('match')" class="taghelper_command"><MT_TRANS phrase="match in body"></span>
    <span id="taghelper_close" onclick="TaggingHelper.close()" class="taghelper_command"><MT_TRANS phrase="close"></span>
<div id="tagging_helper_block" style="display: none;"></div>
</div>
EOT

    my $getbody3 = <<'EOT';
TaggingHelper.getBody = function () {
    // for MT 3.3
    return document.getElementById('text').value
         + '\n'
         + document.getElementById('text_more').value;
}
EOT

    my $getbody4 = <<'EOT';
TaggingHelper.getBody = function () {
    // for MT 4
    // get both current editting field and hidden input fields.
    // currently i don't care about duplication.
    // but it's very nasty. FIXME! 
    return app.editor.getHTML()
         + '\n'
         + document.getElementById('editor-input-content').value
         + '\n'
         + document.getElementById('editor-input-extended').value;
}
EOT

    my $getbody = ($mt_version =~ /^4/) ? $getbody4 : $getbody3;
    $html =~ s/__getbody/$getbody/;
    return $plugin->translate_templatized($html);
}

sub hdlr_mt3_source {
    my ($eh, $app, $tmpl) = @_;
    my $html = _build_html(); 
    my $pattern = quotemeta(<<'EOT');
<input name="tags" id="tags" tabindex="7" value="<TMPL_VAR NAME=TAGS ESCAPE=HTML>" onchange="setDirty()" />
</div>
EOT
    $$tmpl =~ s!($pattern)!$1$html!;
}

sub hdlr_mt4_param {
    my ($eh, $app, $param, $tmpl) = @_;
    my $html = _build_html(); 
    die 'something wrong...'
        unless UNIVERSAL::isa($tmpl, 'MT::Template');
    my $host_node = $tmpl->getElementById('tags')
        or die 'cannot find tags field in the screen.';
    $host_node->innerHTML($host_node->innerHTML . $html);
    1;
}

1;

