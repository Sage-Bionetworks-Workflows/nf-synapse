/*
unit tests for Utils.groovy - no package dependencies
*/

nextflow.enable.dsl = 2

workflow {

  def failures = []

  def check = { String name, Closure test ->
    try {
      test.call()
      println "✅ ${name}"
    }
    catch (Throwable e) {
      println "❌ ${name} — ${e.class.simpleName}: ${e.message}"
      failures << [name: name, error: e]
    }
  }

  // ----------------------------
  // S3 scheme + bucket/path
  // ----------------------------
  check("clean_uri: preserves bucket/path and strips trailing slash") {
    def got = Utils.clean_uri('s3://example-bucket/some_test_dir/')
    assert got == 's3://example-bucket/some_test_dir' : "got=${got}"
  }

  check("clean_uri: removes duplicate + trailing slashes") {
    def got = Utils.clean_uri('s3://example-bucket//some_test_dir///')
    assert got == 's3://example-bucket/some_test_dir' : "got=${got}"
  }

  check("clean_uri: normalizes internal duplicate slashes") {
    def got = Utils.clean_uri('s3://example-bucket/a//b///c/')
    assert got == 's3://example-bucket/a/b/c' : "got=${got}"
  }

  // ----------------------------
  // Bucket-only forms
  // ----------------------------
  check("clean_uri: bucket-only (no trailing slash)") {
    def got = Utils.clean_uri('s3://example-bucket')
    assert got == 's3://example-bucket' : "got=${got}"
  }

  check("clean_uri: bucket-only (with trailing slash)") {
    def got = Utils.clean_uri('s3://example-bucket/')
    assert got == 's3://example-bucket' : "got=${got}"
  }

  // ----------------------------
  // file:// URI (authority is null)
  // ----------------------------
  check("clean_uri: file URI normalization (authority is null)") {
    def got = Utils.clean_uri('file:///tmp//some_dir///')
    assert got == 'file://tmp/some_dir' : "got=${got}"
  }

  check("clean_uri: s3 URI normalization (authority is null)") {
    def got = Utils.clean_uri('s3:///home/ec2-user/nf-synapse/work/synstage/')
    assert got == 's3://home/ec2-user/nf-synapse/work/synstage' : "got=${got}"
  }

  // --------------------------------------
  // Missing scheme should throw exception
  // --------------------------------------
  check("clean_uri: throws if scheme missing, outdir = /<authority>/<path>") {
    boolean threw = false
    try {
      Utils.clean_uri('/tmp/some_dir')
    } catch (Exception e) {
      threw = true
      assert e.message.contains('There must be a scheme') : "msg=${e.message}"
    }
    assert threw : "Expected exception for missing scheme"
  }

  check("clean_uri: throws if authority or path missing, outdir = s3://") {
    boolean threw = false
    try {
      Utils.clean_uri('s3://')
    } catch (Exception e) {
      threw = true
      assert e.message.contains('Expected authority at index 5') : "msg=${e.message}"
    }
    assert threw : "Expected exception for missing authority or path"
  }


  // ----------------------------
  // Summary / exit
  // ----------------------------
  if (failures) {
    println "\n========== TEST SUMMARY =========="
    println "Total: ${failures.size()} failed\n"
    failures.eachWithIndex { f, i ->
      println "${i + 1}) ${f.name}"
    }
    error "Utils tests failed (${failures.size()})."
  } else {
    println "\n✅ All Utils tests passed"
  }
}
