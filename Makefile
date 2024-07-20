clean:
	dzil clean
	rm -rf _Inline

test: clean
	dzil test
