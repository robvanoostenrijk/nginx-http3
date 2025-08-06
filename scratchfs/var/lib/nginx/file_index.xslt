<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:date="http://exslt.org/dates-and-times"
	version="1.0"
	extension-element-prefixes="date">

	<xsl:output method="html" encoding="UTF-8" version="5" />
	<xsl:strip-space elements="*" />

	<xsl:template name="get-file-extension">
		<xsl:param name="path"/>
		<xsl:choose>
			<xsl:when test="contains($path, '/')">
				<xsl:call-template name="get-file-extension">
					<xsl:with-param name="path" select="substring-after($path, '/')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($path, '.')">
				<xsl:call-template name="get-file-extension">
					<xsl:with-param name="path" select="substring-after($path, '.')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$path"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="directory" mode="size">
		<td>--</td>
	</xsl:template>

	<xsl:template match="file" mode="size">
		<td class="size" data-size="{@size}">
			<div class="sizebar">
				<div class="sizebar-bar"></div>
				<div class="sizebar-text">
					<!-- transform a size in bytes into a human readable representation -->
					<xsl:choose>
						<xsl:when test="@size &lt; 1000"><xsl:value-of select="@size" />B</xsl:when>
						<xsl:when test="@size &lt; 1048576"><xsl:value-of select="format-number(@size div 1024, '0.0')" />K</xsl:when>
						<xsl:when test="@size &lt; 1073741824"><xsl:value-of select="format-number(@size div 1048576, '0.0')" />M</xsl:when>
						<xsl:otherwise><xsl:value-of select="format-number((@size div 1073741824), '0.00')" />G</xsl:otherwise>
					</xsl:choose>
				</div>
			</div>
		</td>
	</xsl:template>

	<xsl:template match="directory|file" mode="timestamp">
		<td class="timestamp hideable">
			<time datetime="{ @mtime }">
				<!-- transform an ISO 8601 timestamp into a human readable representation -->
				<xsl:value-of select="concat(substring(@time, 0, 11), ' ', substring(@mtime, 12, 5))" />
			</time>
		</td>
	</xsl:template>

	<xsl:template match="directory" mode="icon">
		<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-folder-filled" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 3a1 1 0 0 1 .608 .206l.1 .087l2.706 2.707h6.586a3 3 0 0 1 2.995 2.824l.005 .176v8a3 3 0 0 1 -2.824 2.995l-.176 .005h-14a3 3 0 0 1 -2.995 -2.824l-.005 -.176v-11a3 3 0 0 1 2.824 -2.995l.176 -.005h4z" stroke-width="0" fill="currentColor"/></svg>
	</xsl:template>

	<xsl:template match="file" mode="icon">
		<xsl:variable name="ext">
			<xsl:call-template name="get-file-extension">
				<xsl:with-param name="path" select="translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')" />
			</xsl:call-template>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test=". = 'README' or . = 'LICENSE'">
				<svg class="icon-license"><use href="#icon-license" /></svg>
			</xsl:when>
			<xsl:when test="contains('|jpg|jpeg|png|gif|webp|tiff|bmp|heif|heic|svg|', concat('|', $ext, '|'))">
				<xsl:choose>
					<xsl:when test="$layout = 'grid'">
						<img loading="lazy" src="{$path}{.}" />
					</xsl:when>
					<xsl:otherwise>
						<svg class="icon-tabler"><use href="#icon-photo" /></svg>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="contains('|mp4|mov|m4v|mpeg|avi|webm|mkv|vob|gifv|3gp|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-movie" /></svg>
			</xsl:when>
			<xsl:when test="contains('|mp3|m4a|aac|ogg|flac|wav|wma|midi|cda|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-music" /></svg>
			</xsl:when>
			<xsl:when test="$ext = 'pdf'">
				<svg class="icon-tabler"><use href="#icon-file-type-pdf" /></svg>
			</xsl:when>
			<xsl:when test="contains('|csv|tsv|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-file-type-csv" /></svg>
			</xsl:when>
			<xsl:when test="contains('|txt|doc|docx|odt|fodt|rtf|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-file-text" /></svg>
			</xsl:when>
			<xsl:when test="contains('|xls|xlsx|ods|fods|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-file-spreadsheet" /></svg>
			</xsl:when>
			<xsl:when test="contains('|ppt|pptx|odp|fodp|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-presentation-analytics" /></svg>
			</xsl:when>
			<xsl:when test="contains('|zip|gz|xz|tar|bz2|7z|rar|xz|zst|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-file-zip" /></svg>
			</xsl:when>
			<xsl:when test="contains('|deb|dpkg|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-brand-debian" /></svg>
			</xsl:when>
			<xsl:when test="contains('|rpm|exe|flatpak|appimage|jar|msi|apk|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-package" /></svg>
			</xsl:when>
			<xsl:when test="$ext = 'ps1'">
				<svg class="icon-tabler"><use href="#icon-brand-powershell" /></svg>
			</xsl:when>
			<xsl:when test="contains('|py|pyc|pyo|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-brand-python" /></svg>
			</xsl:when>
			<xsl:when test="contains('|bash|sh|com|bat|dll|so|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-script" /></svg>
			</xsl:when>
			<xsl:when test="contains('|dmg|pkg|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-brand-finder" /></svg>
			</xsl:when>
			<xsl:when test="contains('|iso|img|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-disc" /></svg>
			</xsl:when>
			<xsl:when test="contains('|md|mdown|markdown|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-markdown" /></svg>
			</xsl:when>
			<xsl:when test="contains('|ttf|otf|woff|woff2|eof|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-file-typography" /></svg>
			</xsl:when>
			<xsl:when test="$ext = 'go'">
				<svg class="icon-tabler"><use href="#icon-brand-golang" /></svg>
			</xsl:when>
			<xsl:when test="contains('|html|htm|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-file-type-html" /></svg>
			</xsl:when>
			<xsl:when test="$ext = 'js'">
				<svg class="icon-tabler"><use href="#icon-file-type-js" /></svg>
			</xsl:when>
			<xsl:when test="$ext = 'css'">
				<svg class="icon-tabler"><use href="#icon-file-type-css" /></svg>
			</xsl:when>
			<xsl:when test="contains('|json|json5|jsonc|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-json" /></svg>
			</xsl:when>
			<xsl:when test="$ext = 'ts'">
				<svg class="icon-tabler"><use href="#icon-file-type-ts" /></svg>
			</xsl:when>
			<xsl:when test="$ext = 'sql'">
				<svg class="icon-tabler"><use href="#icon-file-type-sql" /></svg>
			</xsl:when>
			<xsl:when test="contains('|db|sqlite|bak|mdb|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-database" /></svg>
			</xsl:when>
			<xsl:when test="contains('|eml|email|mailbox|mbox|msg|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-mail" /></svg>
			</xsl:when>
			<xsl:when test="contains('|crt|pem|x509|cer|ca-bundle|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-certificate" /></svg>
			</xsl:when>
			<xsl:when test="contains('|key|keystore|jks|p12|pfx|pub|', concat('|', $ext, '|'))">
				<svg class="icon-tabler"><use href="#icon-key" /></svg>
			</xsl:when>
			<xsl:otherwise>
				<svg class="icon-tabler"><use href="#icon-file" /></svg>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="breadcrumb">
		<xsl:param name="list" />
		<xsl:param name="delimiter" select="'/'" />
		<xsl:param name="remainder" select="$list" />
		<xsl:variable name="newlist">
		<xsl:choose>
			<xsl:when test="contains($list, $delimiter)">
				<xsl:value-of select="normalize-space($list)" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat(normalize-space($list), $delimiter)"/>
			</xsl:otherwise>
		</xsl:choose>
		</xsl:variable>
		<xsl:variable name="first" select="substring-before($newlist, $delimiter)" />
		<xsl:variable name="remaining" select="substring-after($newlist, $delimiter)" />
		<xsl:variable name="current" select="substring-before($remainder, $remaining)" />

		<xsl:choose>
		<xsl:when test="$remaining">
			<xsl:choose>
			<xsl:when test="$first = ''">
				<a href="/">/</a>
			</xsl:when>
			<xsl:otherwise>
				<a href="{$current}"><xsl:value-of select="$first" /></a> /
			</xsl:otherwise>
			</xsl:choose>

			<xsl:call-template name="breadcrumb">
				<xsl:with-param name="list" select="$remaining" />
				<xsl:with-param name="delimiter" select="$delimiter" />
				<xsl:with-param name="remainder" select="$remainder" />
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:choose>
			<xsl:when test="$first = ''">
				<a href="/">/</a>
			</xsl:when>
			<xsl:otherwise>
				<a href="{$current}"><xsl:value-of select="$first" /></a>
			</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="directory|file" mode="list">
		<tr class="file">
			<td class="hideable"></td>
			<td>
				<a href="{.}">
					<xsl:apply-templates select="." mode="icon" />
					<span class="name"><xsl:value-of select="." /></span>
				</a>
			</td>
			<xsl:apply-templates select="." mode="size" />
			<xsl:apply-templates select="." mode="timestamp" />
			<td class="hideable"></td>
		</tr>
	</xsl:template>

	<xsl:template match="directory|file" mode="grid">
		<div class="entry">
			<a href="{$path}{.}" title="{concat(substring(@mtime, 0, 11), ' ', substring(@mtime, 12, 5))}">
				<xsl:apply-templates select="." mode="icon" />
				<div class="name"><xsl:value-of select="." /></div>
				<div class="size"><xsl:apply-templates select="." mode="size" /></div>
			</a>
		</div>
	</xsl:template>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="$path" />
				</title>
				<link rel="canonical" href="{ $path }" />
				<meta charset="utf-8" />
				<meta name="color-scheme" content="light dark" />
				<meta name="viewport" content="width=device-width, initial-scale=1.0" />
				<style>
					* { padding: 0; margin: 0; box-sizing: border-box; }

					body {
						font-family: Inter, system-ui, sans-serif;
						font-size: 16px;
						text-rendering: optimizespeed;
						background-color: #f3f6f7;
						min-height: 100vh;
					}

					img,
					svg {
						vertical-align: middle;
						z-index: 1;
					}

					img {
						max-width: 100%;
						max-height: 100%;
						border-radius: 5px;
					}

					td img {
						max-width: 1.5em;
						max-height: 2em;
						object-fit: cover;
					}

					body,
					a,
					svg,
					.layout.current,
					.layout.current svg,
					.go-up {
						color: #333;
						text-decoration: none;
					}

					.wrapper {
						max-width: 1200px;
						margin-left: auto;
						margin-right: auto;
					}

					header,
					.meta {
						padding-left: 5%;
						padding-right: 5%;
					}

					td a {
						color: #006ed3;
						text-decoration: none;
					}

					td a:hover {
						color: #0095e4;
					}

					td a:visited {
						color: #800080;
					}

					td a:visited:hover {
						color: #b900b9;
					}

					th:first-child,
					td:first-child {
						width: 5%;
					}

					th:last-child,
					td:last-child {
						width: 5%;
					}

					.size,
					.timestamp {
						font-size: 14px;
						font-family: monospace;
					}

					.grid .size {
						font-size: 12px;
						margin-top: .5em;
						color: #496a84;
					}

					header {
						padding-top: 15px;
						padding-bottom: 15px;
						box-shadow: 0px 0px 20px 0px rgb(0 0 0 / 10%);
					}

					.breadcrumbs {
						text-transform: uppercase;
						font-size: 10px;
						letter-spacing: 1px;
						color: #939393;
						margin-bottom: 5px;
						padding-left: 3px;
					}

					h1 {
						font-size: 20px;
						font-family: Poppins, system-ui, sans-serif;
						font-weight: normal;
						white-space: nowrap;
						overflow-x: hidden;
						text-overflow: ellipsis;
						color: #c5c5c5;
					}

					h1 a,
					th a {
						color: #000;
					}

					h1 a {
						padding: 0 3px;
						margin: 0 1px;
					}

					h1 a:hover {
						background: #ffffc4;
					}

					h1 a:first-child {
						margin: 0;
					}

					header,
					main {
						background-color: white;
					}

					main {
						margin: 3em auto 0;
						border-radius: 5px;
						box-shadow: 0 2px 5px 1px rgb(0 0 0 / 5%);
					}

					.meta {
						display: flex;
						gap: 1em;
						font-size: 14px;
						border-bottom: 1px solid #e5e9ea;
						padding-top: 1em;
						padding-bottom: 1em;
					}

					#summary {
						display: flex;
						gap: 1em;
						align-items: center;
						margin-right: auto;
					}

					.filter-container {
						position: relative;
						display: inline-block;
						margin-left: 1em;
					}

					#search-icon {
						color: #777;
						position: absolute;
						height: 1em;
						top: .6em;
						left: .5em;
					}

					#filter {
						padding: .5em 1em .5em 2.5em;
						border: none;
						border: 1px solid #CCC;
						border-radius: 5px;
						font-family: inherit;
						position: relative;
						z-index: 2;
						background: none;
					}

					.layout,
					.layout svg {
						color: #9a9a9a;
					}

					table {
						width: 100%;
						border-collapse: collapse;
					}

					tbody tr,
					tbody tr a,
					.entry a {
						transition: all .15s;
					}

					tbody tr:hover,
					.grid .entry a:hover {
						background-color: #f4f9fd;
					}

					th,
					td {
						text-align: left;
					}

					th {
						position: sticky;
						top: 0;
						background: white;
						white-space: nowrap;
						z-index: 2;
						text-transform: uppercase;
						font-size: 14px;
						letter-spacing: 1px;
						padding: .75em 0;
					}

					td {
						white-space: nowrap;
					}

					td:nth-child(2) {
						width: 75%;
					}

					td:nth-child(2) a {
						padding: 1em 0;
						display: block;
					}

					td:nth-child(3),
					th:nth-child(3) {
						padding: 0 20px 0 20px;
						min-width: 150px;
					}

					td .go-up {
						text-transform: uppercase;
						font-size: 12px;
						font-weight: bold;
					}

					.name,
					.go-up {
						word-break: break-all;
						overflow-wrap: break-word;
						white-space: pre-wrap;
						padding-left: 5px;
					}

					.listing .icon-tabler {
						color: #454545;

						/* svg properties */
						width: 24px;
						height: 24px;

						stroke-width: 2;
						stroke: currentColor;
						fill: none;
						stroke-linecap: round;
						stroke-linejoin: round;
					}

					.listing .icon-tabler-folder-filled {
						color: #ffb900 !important;
					}

					.sizebar {
						position: relative;
						padding: 0.25rem 0.5rem;
						display: flex;
					}

					.sizebar-bar {
						background-color: #dbeeff;
						position: absolute;
						top: 0;
						right: 0;
						bottom: 0;
						left: 0;
						z-index: 0;
						height: 100%;
						pointer-events: none;
					}

					.sizebar-text {
						position: relative;
						z-index: 1;
						overflow: hidden;
						text-overflow: ellipsis;
						white-space: nowrap;

						width: 100%;
						text-align: right;
					}

					.grid {
						display: grid;
						grid-template-columns: repeat(auto-fill, minmax(16em, 1fr));
						gap: 2px;
					}

					.grid .entry {
						position: relative;
						width: 100%;
					}

					.grid .entry a {
						display: flex;
						flex-direction: column;
						align-items: center;
						justify-content: center;
						padding: 1.5em;
						height: 100%;
					}

					.grid .entry svg {
						width: 75px;
						height: 75px;
					}

					.grid .entry img {
						max-height: 200px;
						object-fit: cover;
					}

					.grid .entry .name {
						margin-top: 1em;
					}

					footer {
						padding: 40px 20px;
						font-size: 12px;
						text-align: center;
					}

					.caddy-logo {
						display: inline-block;
						height: 2.5em;
						margin: 0 auto;
					}

					@media (max-width: 600px) {
						.hideable {
							display: none;
						}

						td:nth-child(2) {
							width: auto;
						}

						th:nth-child(3),
						td:nth-child(3) {
							padding-right: 5%;
							text-align: right;
						}

						h1 {
							color: #000;
						}

						h1 a {
							margin: 0;
						}

						#filter {
							max-width: 100px;
						}

						.grid .entry {
							max-width: initial;
						}
					}


					@media (prefers-color-scheme: dark) {
						html {
							background: black; /* overscroll */
						}

						body {
							background: linear-gradient(180deg, rgb(34 50 66) 0%, rgb(26 31 38) 100%);
							background-attachment: fixed;
						}

						body,
						a,
						svg,
						.layout.current,
						.layout.current svg,
							.go-up {
						color: #ccc;
						}

						h1 a,
						th a {
							color: white;
						}

						h1 {
							color: white;
						}

						h1 a:hover {
							background: hsl(213deg 100% 73% / 20%);
						}

						header,
						main,
						.grid .entry {
							background-color: #101720;
						}

						tbody tr:hover,
						.grid .entry a:hover {
							background-color: #162030;
							color: #fff;
						}

						th {
						background-color: #18212c;
						}

						td a,
						.listing .icon-tabler {
							color: #abc8e3;
						}

						td a:hover,
						td a:hover .icon-tabler {
							color: white;
						}

						td a:visited {
							color: #cd53cd;
						}

						td a:visited:hover {
							color: #f676f6;
						}

						#search-icon {
							color: #7798c4;
						}

						#filter {
							color: #ffffff;
							border: 1px solid #29435c;
						}

						.meta {
							border-bottom: 1px solid #222e3b;
						}

						.sizebar-bar {
							background-color: #1f3549;
						}

						.grid .entry a {
							background-color: #080b0f;
						}

						#Wordmark path,
						#R path {
							fill: #ccc !important;
						}
						#R circle {
							stroke: #ccc !important;
						}
					}
				</style>
				<xsl:if test="$layout = 'grid'">
					<style>.wrapper { max-width: none; } main { margin-top: 1px; }</style>
				</xsl:if>
			</head>
			<body onload="initPage()">
				<header>
					<div class="wrapper">
						<div class="breadcrumbs">Folder Path</div>
						<h1>
							<xsl:call-template name="breadcrumb">
								<xsl:with-param name="list" select="$path" />
							</xsl:call-template>
						</h1>
					</div>
				</header>
				<div class="wrapper">
					<main>
						<div class="meta">
							<div id="summary">
								<span class="meta-item">
									<b><xsl:value-of select="count(/list/directory)" /></b> director<xsl:choose><xsl:when test="count(/list/directory) = 1">y</xsl:when><xsl:otherwise>ies</xsl:otherwise></xsl:choose>
								</span>
								<span class="meta-item">
									<b><xsl:value-of select="count(/list/file)" /></b> file<xsl:if test="count(/list/file) != 0">s</xsl:if>
								</span>
								<!--
								{{- if ne 0 .Limit}}
								<span class="meta-item">
									(of which only <b>{{.Limit}}</b> are displayed)
								</span>
								{{- end}}
								-->
							</div>
							<a href="javascript:queryParam('layout', '')" id="layout-list">
								<xsl:attribute name="class">
									<xsl:choose> 
										<xsl:when test="$layout != 'grid'">layout current</xsl:when>
										<xsl:otherwise>layout</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>

								<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-layout-list" width="16" height="16" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z"/><path d="M4 14m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v2a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z"/></svg>
								List
							</a>
							<a href="javascript:queryParam('layout', 'grid')" id="layout-grid">
								<xsl:attribute name="class">
									<xsl:choose> 
										<xsl:when test="$layout = 'grid'">layout current</xsl:when>
										<xsl:otherwise>layout</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
								<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-layout-grid" width="16" height="16" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 4m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z"/><path d="M14 4m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z"/><path d="M4 14m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z"/><path d="M14 14m0 1a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4a1 1 0 0 1 -1 1h-4a1 1 0 0 1 -1 -1z"/></svg>
								Grid
							</a>
						</div>

						<div class="listing">
							<xsl:choose>
								<xsl:when test="$layout = 'grid'">
									<xsl:attribute name="class">listing grid</xsl:attribute>
									<xsl:apply-templates select="/list/node()" mode="grid">
										<xsl:sort select="local-name()" order="ascending" />
										<xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending" />
									</xsl:apply-templates>
								</xsl:when>
								<xsl:otherwise>
									<table aria-describedby="summary">
										<thead>
											<tr>
												<th class="hideable"></th>
												<th>
													<xsl:choose>
														<xsl:when test="$sort = 'namedirfirst' and $order != 'desc'">
															<a href="?sort=namedirfirst&amp;order=desc" class="icon">
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-up" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 14l-6 -6l-6 6h12"/></svg>
															</a>
														</xsl:when>
														<xsl:when test="$sort = 'namedirfirst' and $order != 'asc'">
															<a href="?sort=namedirfirst&amp;order=asc" class="icon">
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-down" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 10l6 6l6 -6h-12"/></svg>
															</a>
														</xsl:when>
														<xsl:otherwise>
															<a href="?sort=namedirfirst&amp;order=asc" class="icon sort">
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-up" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 14l-6 -6l-6 6h12"/></svg>
															</a>
														</xsl:otherwise>
													</xsl:choose>

													<xsl:choose>
														<xsl:when test="$sort = 'name' and $order != 'desc'">
															<a href="?sort=name&amp;order=desc">
																Name
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-up" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 14l-6 -6l-6 6h12"/></svg>
															</a>
														</xsl:when>
														<xsl:when test="$sort = 'name' and $order != 'asc'">
															<a href="?sort=name&amp;order=asc">
																Name
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-down" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 10l6 6l6 -6h-12"/></svg>
															</a>
														</xsl:when>
														<xsl:otherwise>
															<a href="?sort=name&amp;order=asc">Name</a>
														</xsl:otherwise>
													</xsl:choose>

													<div class="filter-container">
														<svg id="search-icon" xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-search" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0"/><path d="M21 21l-6 -6"/></svg>
														<input type="search" placeholder="Search" id="filter" onkeyup='filter()' />
													</div>
												</th>
												<th>

													<xsl:choose>
														<xsl:when test="$sort = 'size' and $order != 'desc'">
															<a href="?sort=size&amp;order=desc">
																Size
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-up" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 14l-6 -6l-6 6h12"/></svg>
															</a>
														</xsl:when>
														<xsl:when test="$sort = 'size' and $order != 'asc'">
															<a href="?sort=size&amp;order=asc">
																Size
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-down" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 10l6 6l6 -6h-12"/></svg>
															</a>
														</xsl:when>
														<xsl:otherwise>
															<a href="?sort=size&amp;order=asc">Size</a>
														</xsl:otherwise>
													</xsl:choose>
												</th>
												<th class="hideable">
													<xsl:choose>
														<xsl:when test="$sort = 'time' and $order != 'desc'">
															<a href="?sort=time&amp;order=desc">
																Modified
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-up" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 14l-6 -6l-6 6h12"/></svg>
															</a>
														</xsl:when>
														<xsl:when test="$sort = 'time' and $order != 'asc'">
															<a href="?sort=time&amp;order=asc">
																Modified
																<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-caret-down" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 10l6 6l6 -6h-12"/></svg>
															</a>
														</xsl:when>
														<xsl:otherwise>
															<a href="?sort=time&amp;order=asc">Modified</a>
														</xsl:otherwise>
													</xsl:choose>
												</th>
												<th class="hideable"></th>
											</tr>
										</thead>
										<tbody>
											<xsl:if test="string-length($path) > 0">
												<tr>
													<td class="hideable"></td>
													<td>
														<a href="..">
															<svg xmlns="http://www.w3.org/2000/svg" class="icon icon-tabler icon-tabler-corner-left-up" width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M18 18h-6a3 3 0 0 1 -3 -3v-10l-4 4m8 0l-4 -4"/></svg>
															<span class="go-up">Up</span>
														</a>
													</td>
													<td></td>
													<td class="hideable"></td>
													<td class="hideable"></td>
												</tr>
											</xsl:if>

											<xsl:choose>
												<xsl:when test="$sort = 'namedirfirst' and $order = 'asc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="local-name()" order="ascending" />
														<xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:when test="$sort = 'namedirfirst' and $order = 'desc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="local-name()" order="descending" />
														<xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="descending" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:when test="$sort = 'name' and $order = 'asc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:when test="$sort = 'name' and $order = 'desc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="descending" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:when test="$sort = 'size' and $order = 'asc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="@size" order="ascending" data-type="number" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:when test="$sort = 'size' and $order = 'desc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="@size" order="descending" data-type="number" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:when test="$sort = 'time' and $order = 'asc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="@mtime" order="ascending" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:when test="$sort = 'time' and $order = 'desc'">
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="@mtime" order="descending" />
													</xsl:apply-templates>
												</xsl:when>
												<xsl:otherwise>
													<xsl:apply-templates select="/list/node()" mode="list">
														<xsl:sort select="local-name()" order="ascending" />
														<xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending" />
													</xsl:apply-templates>
												</xsl:otherwise>
											</xsl:choose>
										</tbody>
									</table>
								</xsl:otherwise>
							</xsl:choose>
						</div>
					</main>
				</div>
				<footer><xsl:value-of select="$footer" /></footer>
				<div style="display: none;">
					<svg xmlns="http://www.w3.org/2000/svg">
						<symbol id="icon-brand-debian" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 17c-2.397 -.943 -4 -3.153 -4 -5.635c0 -2.19 1.039 -3.14 1.604 -3.595c2.646 -2.133 6.396 -.27 6.396 3.23c0 2.5 -2.905 2.121 -3.5 1.5c-.595 -.621 -1 -1.5 -.5 -2.5"/><path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0"/></symbol>
						<symbol id="icon-brand-finder" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 4m0 1a1 1 0 0 1 1 -1h16a1 1 0 0 1 1 1v14a1 1 0 0 1 -1 1h-16a1 1 0 0 1 -1 -1z"/><path d="M7 8v1"/><path d="M17 8v1"/><path d="M12.5 4c-.654 1.486 -1.26 3.443 -1.5 9h2.5c-.19 2.867 .094 5.024 .5 7"/><path d="M7 15.5c3.667 2 6.333 2 10 0"/></symbol>
						<symbol id="icon-brand-golang" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15.695 14.305c1.061 1.06 2.953 .888 4.226 -.384c1.272 -1.273 1.444 -3.165 .384 -4.226c-1.061 -1.06 -2.953 -.888 -4.226 .384c-1.272 1.273 -1.444 3.165 -.384 4.226z"/><path d="M12.68 9.233c-1.084 -.497 -2.545 -.191 -3.591 .846c-1.284 1.273 -1.457 3.165 -.388 4.226c1.07 1.06 2.978 .888 4.261 -.384a3.669 3.669 0 0 0 1.038 -1.921h-2.427"/><path d="M5.5 15h-1.5"/><path d="M6 9h-2"/><path d="M5 12h-3"/></symbol>
						<symbol id="icon-brand-powershell" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4.887 20h11.868c.893 0 1.664 -.665 1.847 -1.592l2.358 -12c.212 -1.081 -.442 -2.14 -1.462 -2.366a1.784 1.784 0 0 0 -.385 -.042h-11.868c-.893 0 -1.664 .665 -1.847 1.592l-2.358 12c-.212 1.081 .442 2.14 1.462 2.366c.127 .028 .256 .042 .385 .042z"/><path d="M9 8l4 4l-6 4"/><path d="M12 16h3"/></symbol>
						<symbol id="icon-brand-python" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 9h-7a2 2 0 0 0 -2 2v4a2 2 0 0 0 2 2h3"/><path d="M12 15h7a2 2 0 0 0 2 -2v-4a2 2 0 0 0 -2 -2h-3"/><path d="M8 9v-4a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v5a2 2 0 0 1 -2 2h-4a2 2 0 0 0 -2 2v5a2 2 0 0 0 2 2h4a2 2 0 0 0 2 -2v-4"/><path d="M11 6l0 .01"/><path d="M13 18l0 .01"/></symbol>
						<symbol id="icon-certificate" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 15m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M13 17.5v4.5l2 -1.5l2 1.5v-4.5"/><path d="M10 19h-5a2 2 0 0 1 -2 -2v-10c0 -1.1 .9 -2 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -1 1.73"/><path d="M6 9l12 0"/><path d="M6 12l3 0"/><path d="M6 15l2 0"/></symbol>
						<symbol id="icon-database" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 6m-8 0a8 3 0 1 0 16 0a8 3 0 1 0 -16 0"/><path d="M4 6v6a8 3 0 0 0 16 0v-6"/><path d="M4 12v6a8 3 0 0 0 16 0v-6"/></symbol>
						<symbol id="icon-disc" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0"/><path d="M12 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0"/><path d="M7 12a5 5 0 0 1 5 -5"/><path d="M12 17a5 5 0 0 0 5 -5"/></symbol>
						<symbol id="icon-file-spreadsheet" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"/><path d="M8 11h8v7h-8z"/><path d="M8 15h8"/><path d="M11 11v7"/></symbol>
						<symbol id="icon-file-text" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"/><path d="M9 9l1 0"/><path d="M9 13l6 0"/><path d="M9 17l6 0"/></symbol>
						<symbol id="icon-file-type-css" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4"/><path d="M8 16.5a1.5 1.5 0 0 0 -3 0v3a1.5 1.5 0 0 0 3 0"/><path d="M11 20.25c0 .414 .336 .75 .75 .75h1.25a1 1 0 0 0 1 -1v-1a1 1 0 0 0 -1 -1h-1a1 1 0 0 1 -1 -1v-1a1 1 0 0 1 1 -1h1.25a.75 .75 0 0 1 .75 .75"/><path d="M17 20.25c0 .414 .336 .75 .75 .75h1.25a1 1 0 0 0 1 -1v-1a1 1 0 0 0 -1 -1h-1a1 1 0 0 1 -1 -1v-1a1 1 0 0 1 1 -1h1.25a.75 .75 0 0 1 .75 .75"/></symbol>
						<symbol id="icon-file-type-csv" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4"/><path d="M7 16.5a1.5 1.5 0 0 0 -3 0v3a1.5 1.5 0 0 0 3 0"/><path d="M10 20.25c0 .414 .336 .75 .75 .75h1.25a1 1 0 0 0 1 -1v-1a1 1 0 0 0 -1 -1h-1a1 1 0 0 1 -1 -1v-1a1 1 0 0 1 1 -1h1.25a.75 .75 0 0 1 .75 .75"/><path d="M16 15l2 6l2 -6"/></symbol>
						<symbol id="icon-file-type-html" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4"/><path d="M2 21v-6"/><path d="M5 15v6"/><path d="M2 18h3"/><path d="M20 15v6h2"/><path d="M13 21v-6l2 3l2 -3v6"/><path d="M7.5 15h3"/><path d="M9 15v6"/></symbol>
						<symbol id="icon-file-type-js" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M3 15h3v4.5a1.5 1.5 0 0 1 -3 0"/><path d="M9 20.25c0 .414 .336 .75 .75 .75h1.25a1 1 0 0 0 1 -1v-1a1 1 0 0 0 -1 -1h-1a1 1 0 0 1 -1 -1v-1a1 1 0 0 1 1 -1h1.25a.75 .75 0 0 1 .75 .75"/><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2h-1"/></symbol>
						<symbol id="icon-file-type-pdf" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4"/><path d="M5 18h1.5a1.5 1.5 0 0 0 0 -3h-1.5v6"/><path d="M17 18h2"/><path d="M20 15h-3v6"/><path d="M11 15v6h1a2 2 0 0 0 2 -2v-2a2 2 0 0 0 -2 -2h-1z"/></symbol>
						<symbol id="icon-file-type-sql" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M5 20.25c0 .414 .336 .75 .75 .75h1.25a1 1 0 0 0 1 -1v-1a1 1 0 0 0 -1 -1h-1a1 1 0 0 1 -1 -1v-1a1 1 0 0 1 1 -1h1.25a.75 .75 0 0 1 .75 .75"/><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v4"/><path d="M18 15v6h2"/><path d="M13 15a2 2 0 0 1 2 2v2a2 2 0 1 1 -4 0v-2a2 2 0 0 1 2 -2z"/><path d="M14 20l1.5 1.5"/></symbol>
						<symbol id="icon-file-type-ts" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M5 12v-7a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2h-1"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M9 20.25c0 .414 .336 .75 .75 .75h1.25a1 1 0 0 0 1 -1v-1a1 1 0 0 0 -1 -1h-1a1 1 0 0 1 -1 -1v-1a1 1 0 0 1 1 -1h1.25a.75 .75 0 0 1 .75 .75"/><path d="M3.5 15h3"/><path d="M5 15v6"/></symbol>
						<symbol id="icon-file-typography" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"/><path d="M11 18h2"/><path d="M12 18v-7"/><path d="M9 12v-1h6v1"/></symbol>
						<symbol id="icon-file-zip" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 20.735a2 2 0 0 1 -1 -1.735v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2h-1"/><path d="M11 17a2 2 0 0 1 2 2v2a1 1 0 0 1 -1 1h-2a1 1 0 0 1 -1 -1v-2a2 2 0 0 1 2 -2z"/><path d="M11 5l-1 0"/><path d="M13 7l-1 0"/><path d="M11 9l-1 0"/><path d="M13 11l-1 0"/><path d="M11 13l-1 0"/><path d="M13 15l-1 0"/></symbol>
						<symbol id="icon-file" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M14 3v4a1 1 0 0 0 1 1h4"/><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2z"/></symbol>
						<symbol id="icon-json" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M20 16v-8l3 8v-8"/><path d="M15 8a2 2 0 0 1 2 2v4a2 2 0 1 1 -4 0v-4a2 2 0 0 1 2 -2z"/><path d="M1 8h3v6.5a1.5 1.5 0 0 1 -3 0v-.5"/><path d="M7 15a1 1 0 0 0 1 1h1a1 1 0 0 0 1 -1v-2a1 1 0 0 0 -1 -1h-1a1 1 0 0 1 -1 -1v-2a1 1 0 0 1 1 -1h1a1 1 0 0 1 1 1"/></symbol>
						<symbol id="icon-key" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M16.555 3.843l3.602 3.602a2.877 2.877 0 0 1 0 4.069l-2.643 2.643a2.877 2.877 0 0 1 -4.069 0l-.301 -.301l-6.558 6.558a2 2 0 0 1 -1.239 .578l-.175 .008h-1.172a1 1 0 0 1 -.993 -.883l-.007 -.117v-1.172a2 2 0 0 1 .467 -1.284l.119 -.13l.414 -.414h2v-2h2v-2l2.144 -2.144l-.301 -.301a2.877 2.877 0 0 1 0 -4.069l2.643 -2.643a2.877 2.877 0 0 1 4.069 0z"/><path d="M15 9h.01"/></symbol>
						<symbol id="icon-license" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 21h-9a3 3 0 0 1 -3 -3v-1h10v2a2 2 0 0 0 4 0v-14a2 2 0 1 1 2 2h-2m2 -4h-11a3 3 0 0 0 -3 3v11"/><path d="M9 7l4 0"/><path d="M9 11l4 0"/></symbol>
						<symbol id="icon-mail" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 7a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-10z"/><path d="M3 7l9 6l9 -6"/></symbol>
						<symbol id="icon-markdown" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M3 5m0 2a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2z"/><path d="M7 15v-6l2 2l2 -2v6"/><path d="M14 13l2 2l2 -2m-2 2v-6"/></symbol>
						<symbol id="icon-movie" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z"/><path d="M8 4l0 16"/><path d="M16 4l0 16"/><path d="M4 8l4 0"/><path d="M4 16l4 0"/><path d="M4 12l16 0"/><path d="M16 8l4 0"/><path d="M16 16l4 0"/></symbol>
						<symbol id="icon-music" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M6 17m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M16 17m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0"/><path d="M9 17l0 -13l10 0l0 13"/><path d="M9 8l10 0"/></symbol>
						<symbol id="icon-package" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M12 3l8 4.5l0 9l-8 4.5l-8 -4.5l0 -9l8 -4.5"/><path d="M12 12l8 -4.5"/><path d="M12 12l0 9"/><path d="M12 12l-8 -4.5"/><path d="M16 5.25l-8 4.5"/></symbol>
						<symbol id="icon-photo" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M15 8h.01"/><path d="M3 6a3 3 0 0 1 3 -3h12a3 3 0 0 1 3 3v12a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3v-12z"/><path d="M3 16l5 -5c.928 -.893 2.072 -.893 3 0l5 5"/><path d="M14 14l1 -1c.928 -.893 2.072 -.893 3 0l3 3"/></symbol>
						<symbol id="icon-presentation-analytics" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M9 12v-4"/><path d="M15 12v-2"/><path d="M12 12v-1"/><path d="M3 4h18"/><path d="M4 4v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2 -2v-10"/><path d="M12 16v4"/><path d="M9 20h6"/></symbol>
						<symbol id="icon-script" viewBox="0 0 24 24"><path stroke="none" d="M0 0h24v24H0z" fill="none"/><path d="M17 20h-11a3 3 0 0 1 0 -6h11a3 3 0 0 0 0 6h1a3 3 0 0 0 3 -3v-11a2 2 0 0 0 -2 -2h-10a2 2 0 0 0 -2 2v8"/></symbol>
					</svg>
				</div>

				<script>
				const filterEl = document.getElementById('filter');
				filterEl?.focus({ preventScroll: true });

				function initPage() {
					// populate and evaluate filter
					if (!filterEl?.value) {
						const filterParam = new URL(window.location.href).searchParams.get('filter');
						if (filterParam) {
							filterEl.value = filterParam;
						}
					}
					filter();

					// fill in size bars
					let largest = 0;
					document.querySelectorAll('.size').forEach(el => {
						largest = Math.max(largest, Number(el.dataset.size));
					});

					document.querySelectorAll('.size').forEach(el => {
						const size = Number(el.dataset.size);
						const sizebar = el.querySelector('.sizebar-bar');
						if (sizebar) {
							sizebar.style.width = `${size/largest * 100}%`;
						}
					});
				}

				function filter() {
					if (!filterEl) return;

					const q = filterEl.value.trim().toLowerCase();
					document.querySelectorAll('tr.file').forEach(function(el) {
						if (!q) {
							el.style.display = '';
							return;
						}
						const nameEl = el.querySelector('.name');
						const nameVal = nameEl.textContent.trim().toLowerCase();
						if (nameVal.indexOf(q) !== -1) {
							el.style.display = '';
						} else {
							el.style.display = 'none';
						}
					});
				}

				function queryParam(k, v) {
					const qs = new URLSearchParams(window.location.search);
					if (!v) {
						qs.delete(k);
					} else {
						qs.set(k, v);
					}
					const qsStr = qs.toString();
					if (qsStr) {
						window.location.search = qsStr;
					} else {
						window.location = window.location.pathname;
					}
				}

				function localizeDatetime(e, index, ar) {
					if (e.textContent === undefined) {
						return;
					}
					var d = new Date(e.getAttribute('datetime'));
					if (isNaN(d)) {
						d = new Date(e.textContent);
						if (isNaN(d)) {
							return;
						}
					}
					e.textContent = 
					d.toLocaleString("en-GB", {
						year: "numeric",
						month: "short",
						day: "2-digit"
					}) + " " +
					d.toLocaleString("en-GB", {
						hour: "2-digit",
						minute: "2-digit",
						second: "2-digit"
					})
				}

				var timeList = Array.prototype.slice.call(document.getElementsByTagName("time"));
				timeList.forEach(localizeDatetime);
				</script>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
