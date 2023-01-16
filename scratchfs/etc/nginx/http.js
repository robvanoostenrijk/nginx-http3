function echo(r) {
	r.headersOut["Content-Type"] = "text/plain";
	r.headersOut["X-HTTP-Version"] = `${r.variables.http2}${r.variables.http3}`;

	let output = `${r.method} ${r.uri}${r.variables.is_args}${r.variables.args||""} ${r.variables.server_protocol}\n`;

	r.rawHeadersIn
	.sort((a, b) => {
		if (a[0] < b[0]) { return -1; }
		if (a[0] > b[0]) { return 1; }
		return 0;
	})
	.forEach(h => {
		output += `${h[0]}: ${h[1]}\n`;
	});

	if (r.method == "POST") {
		output += "\n";
		output += r.requestText;
	}

	r.return(200, output);
}

export default { echo };
