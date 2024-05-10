# Gloo Edge Portal - Validation

## Installation

Add Gloo EE and the Gloo Portal Helm repos:
```
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
helm repo add gloo-portal https://storage.googleapis.com/dev-portal-helm
```

Export your Gloo Edge License Key to an environment variable:
```
export GLOO_EDGE_LICENSE_KEY={your license key}
```

Install Gloo Edge:
```
cd install
./install-gloo-edge-enterprise-portal-with-helm.sh
```

> NOTE
> The Gloo Edge and Gloo Portal versions that will be installed are set in a variable at the top of the `install/install-gloo-edge-enterprise-portal-with-helm.sh` installation script.

## Setup the environment

Run the `install/setup.sh` script to setup the environment:

- Deploy the HTTPBin service (this service is simply used as a dummy backend for the APIProduct)
- Deploy the APIDoc and associated ConfigMap
- Deploy the APIProduct
- Deploy the Environment
- Deploy the Portal

```
./setup.sh
```

## Reproducer

The `setup.sh` script has setup the environment in such a way that a `VirtualService` with warnings is deployed:

```
glooctl check

Checking deployments... OK
Checking pods... OK
Checking upstreams... OK
Checking upstream groups... OK
Checking auth configs... OK
Checking rate limit configs... OK
Checking VirtualHostOptions... OK
Checking RouteOptions... OK
Checking secrets... OK
Checking virtual services... 1 Errors!
Checking gateways... OK
Checking proxies... OK
Checking rate limit server... OK
Error: 1 error occurred:
        * Found virtual service with warnings by 'gloo-system': gloo-portal test-environment (Reason: warning: 
  virtual host [gloo-portal.test-environment] has conflicting matcher: regex:"/org/[^/]+?"  methods:"GET"  methods:"OPTIONS"
virtual host [gloo-portal.test-environment] has conflicting matcher: regex:"/org/[^/]+?/children"  methods:"GET"  methods:"OPTIONS"
virtual host [gloo-portal.test-environment] has conflicting matcher: regex:"/org/[^/]+?/parents"  methods:"GET"  methods:"OPTIONS")
```

When we now set the validation to `allowWarnings: false`, the validation will be disabled. We can see that message in the Gloo pod logs.

```
kubectl -n gloo-system patch settings default --type='json' -p '[{"op": "replace", "path": "/spec/gateway/validation/allowWarnings", "value": false}]'
```

```
GLOO=$(kubectl -n gloo-system get -A pods --selector=gloo=gloo -o jsonpath='{.items[*].metadata.name}')
kubectl -n gloo-system logs -f $GLOO
```

You will see an error in the logs stating that _"validation is disabled due to an invalid resource which has been written to storage"_.

> {"level":"error","ts":"2024-05-10T11:00:44.860Z","logger":"gloo-ee.v1.event_loop.setup","caller":"setup/setup_syncer.go:977","msg":"gloo main event loop","version":"1.16.8","error":"event_loop.gloo: 1 error occurred:\n\t* validation is disabled due to an invalid resource which has been written to storage. Please correct any Rejected resources to re-enable validation.: 2 errors occurred:\n\t* invalid resource gloo-portal.test-environment\n\t* WARN: \n  [virtual host [gloo-portal.test-environment] has conflicting matcher: regex:\"/org/[^/]+?\"  methods:\"GET\"  methods:\"OPTIONS\" virtual host [gloo-portal.test-environment] has conflicting matcher: regex:\"/org/[^/]+?/children\"  methods:\"GET\"  methods:\"OPTIONS\" virtual host [gloo-portal.test-environment] has conflicting matcher: regex:\"/org/[^/]+?/parents\"  methods:\"GET\"  methods:\"OPTIONS\"]\n\n\n\n","errorVerbose":"1 error occurred:\n\t* validation is disabled due to an invalid resource which has been written to storage. Please correct any Rejected resources to re-enable validation.: 2 errors occurred:\n\t* invalid resource gloo-portal.test-environment\n\t* WARN: \n  [virtual host [gloo-portal.test-environment] has conflicting matcher: regex:\"/org/[^/]+?\"  methods:\"GET\"  methods:\"OPTIONS\" virtual host [gloo-portal.test-environment] has conflicting matcher: regex:\"/org/[^/]+?/children\"  methods:\"GET\"  methods:\"OPTIONS\" virtual host [gloo-portal.test-environment] has conflicting matcher: regex:\"/org/[^/]+?/parents\"  methods:\"GET\"  methods:\"OPTIONS\"]\n\n\n\n\nevent_loop.gloo\ngithub.com/solo-io/go-utils/errutils.AggregateErrs\n\t/go/pkg/mod/github.com/solo-io/go-utils@v0.24.8/errutils/aggregate_errs.go:19\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1650","stacktrace":"github.com/solo-io/gloo/projects/gloo/pkg/syncer/setup.RunGlooWithExtensions.func10\n\t/go/pkg/mod/github.com/solo-io/gloo@v1.16.10/projects/gloo/pkg/syncer/setup/setup_syncer.go:977"}

You can re-enable validation by deleting and re-applying the `Environment`:

```
kubectl delete -f environment/test-environment.yaml
kubectl apply -f environment/test-environment.yaml
```

Notice that when the validation has been re-enabled, the creation of the `VirtualService` is blocked by the validating webhook. Check that the `VirtualService` has not been created:

```
kubectl get vs -A
```

... and observe that the status of the `Environment` states that the creation of the `VirtualService` has been blocked:

```
kubectl -n gloo-portal get environment test-environment -o yaml
```

> reason: "routing error: 1 error occurred:\n\t* writing resource test-environment.gloo-portal.
    failed: admission webhook \"gloo.gloo-system.svc\" denied the request: resource
    incompatible with current Gloo snapshot: [Validating *v1.VirtualService failed:
    1 error occurred:\n\t* Validating *v1.VirtualService failed: validating *v1.VirtualService
    name:\"test-environment\"  namespace:\"gloo-portal\": 1 error occurred:\n\t* could
    not render proxy: 2 errors occurred:\n\t* invalid resource gloo-portal.test-environment\n\t*
    WARN: \n  [virtual host [gloo-portal.test-environment] has conflicting matcher:
    regex:\"/org/[^/]+?\"  methods:\"GET\"  methods:\"OPTIONS\" virtual host [gloo-portal.test-environment]
    has conflicting matcher: regex:\"/org/[^/]+?/children\"  methods:\"GET\"  methods:\"OPTIONS\"
    virtual host [gloo-portal.test-environment] has conflicting matcher: regex:\"/org/[^/]+?/parents\"
    \ methods:\"GET\"  methods:\"OPTIONS\"]\n\n\n\n\n\n]\n\n"
  state: Failed


# Conclusion
When you reconfigure validation (i.e. the validating webhook), and the system is in a state where an invalid resource has already been written to storage, validation is disabled until that resources is removed from storage.