# $Id$

package MT::Plugin::TaggingHelper;

use strict;
use MT::Template::Context;
use MT::Plugin;
@MT::Plugin::TaggingHelper::ISA = qw(MT::Plugin);

use vars qw($PLUGIN_NAME $VERSION);
$PLUGIN_NAME = 'TaggingHelper';
$VERSION = '0.1';

use MT;
my $plugin = new MT::Plugin::TaggingHelper({
    name => $PLUGIN_NAME,
    version => $VERSION,
    description => "<MT_TRANS phrase='description of TaggingHelper'>",
    doc_link => 'http://blog.aklaswad.com/mtplugins/tagginghelper/',
    author_name => 'Akira Sawada',
    author_link => 'http://blog.aklaswad.com/',
    l10n_class => 'TaggingHelper::L10N',
});

MT->add_plugin($plugin);

#----- Transformer
#----- Transformer(MT4)
MT->add_callback('template_param.edit_entry', 9, $plugin, \&hdlr_mt4_param);

#----- Transformer(MT4)

sub hdlr_mt4_param {
    my ($eh, $app, $param, $tmpl) = @_;
    my $html = <<'EOT';
<style type="text/css">

#tagging_helper_block {
    margin: 10px 0;
    line-height: 1.8em;
}

.taghelper_tag {
    margin: 0 5px;
}

.taghelper_tag_selected {
    margin: 0 5px;
    background-color: #def;
}

</style>

<script type="text/javascript">
var taghelper_ready = 0;
var taghelper_display = 0;
function taghelper_open() {
    var block = document.getElementById('tagging_helper_block');
    if (block.style.display == 'none') {
        block.style.display = 'block';
    }
    else {
        block.style.display = 'none';
    }

    if (taghelper_ready){ return }

    function compareStrAscend(a, b){
        return a.localeCompare(b);
    }
    var tagary = [];
    for (var tag in tags ){
        tagary.add(tag);
    }
    
    tagary.sort(compareStrAscend);

    var v = document.getElementById('tags').value;
    for (var i=0; i< tagary.length; i++) {
        var tag = tagary[i];
        var exp = new RegExp("^(.*, ?)?" + tag + "( ?\,.*)?$");
        if (exp.test(v)) {
            block.innerHTML += '<a href="javascript:void(taghelper_action(\'' + tag + '\'))" class="taghelper_tag_selected", id="taghelper_tag_' + tag + '">' + tag + '</a>';
        }
        else {
            block.innerHTML += '<a href="javascript:void(taghelper_action(\'' + tag + '\'))" class="taghelper_tag", id="taghelper_tag_' + tag + '">' + tag + '</a>';
        }
    }
        
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

<a href="javascript: void(taghelper_open())" class="add-new-category-link"><__trans phrase="old tags"></a>
<div id="tagging_helper_block" style="display: none;"></div>
EOT
    $html = $plugin->translate_templatized($html); 
    die 'something wrong...' unless UNIVERSAL::isa($tmpl, 'MT::Template');
 
    my $host_node = $tmpl->getElementById('tags')
        or die 'cannot get useful-links block';

    $host_node->innerHTML($host_node->innerHTML . $html);
    1;
}

1;
