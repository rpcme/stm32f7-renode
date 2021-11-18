#! /bin/bash
#set -x
function usage()
{
    code=${1:-0}
    echo 'create-iotcore-credential.sh [args...]'
    echo ''
    echo 'Create a thing-certificate-policy tuple.'
    echo ''
    echo '-t [thing_name]  (REQUIRED) the iot thing name'
    echo '-n [policy name] (REQUIRED) the iot policy name'
    echo '-F               (OPTIONAL) Force.  Do not check it objects exist.'
    echo '-f [policy file] (OPTIONAL) when policy does not exist, use this policy file'
    echo '-i [aws|csr]     (OPTIONAL) default:aws'
    echo '-s [csr_file]    (OPTIONAL) when using private pki, use this csr'
    echo '-o [dir]         (OPTIONAL) default: $volatile_dir/$thing_name'
    echo '-s [name]        (OPTIONAL) Add an AWS Secrets Manager item with this info'
    echo '-e               (OPTIONAL) export worthwhile variants to file'
    echo ''
    echo '$volatile_dir by default is $(dirname $0)/../../volatile'
    echo ''
    echo 'See also:'
    exit $code
}

FORCE=0
volatile_dir=$(dirname $0)/../../volatile

while getopts "eFo:t:n:f:h:s:" opt; do
    case ${opt} in
        t)  THING_NAME=$OPTARG
            ;;
        F)  FORCE=1
            ;;
        f)  POLICY_FILE=$OPTARG
            ;;
        n)  POLICY_NAME=$OPTARG
            ;;
        s)  SECRET_NAME=$OPTARG
            ;;
        o)  volatile_dir=$OPTARG
            ;;
        h)  usage 0
            ;;
    esac
done

region=${region:-us-east-1}
profile=${profile:-default}
std_awscli_args="--output text --region ${region} --profile ${profile}"

if test x"$THING_NAME" == x; then usage 1; fi
if test x"$POLICY_NAME" == x; then usage 1; fi

ACCOUNT_ID=$(aws ${std_awscli_args} sts get-caller-identity --output text --query Account)

function thing_exists {
    _thing_name=$1

    echo "Checking if thing name exists.  This can take a long time if you have a lot of things registered."
    result=$(aws iot list-things ${std_awscli_args} \
        --query "things[?thingName=='$_thing_name'].thingName")

    if test x"$result" == x; then return 1; fi

    return 0
}

function get_thing_arn {
    _thing_name=$1

    echo "Retrieving thing ARN.  This can take a long time if you have a lot of things registered."
    THING_ARN=$(aws iot list-things ${std_awscli_args} \
        --query "policies[?thingName=='$_thing_name'].thingArn")

    if test $? != 0; then return 1; fi

    return 0
    echo stub
}

function create_thing {
    _thing_name=$1

    THING_ARN=$(aws iot create-thing ${std_awscli_args}                                        \
                    --thing-name ${_thing_name}                                         \
                    --query thingArn)

    if test $? != 0; then return 1; fi

    return 0
}

function policy_exists {
    _policy_name=$1
    result=$(aws iot list-policies ${std_awscli_args} \
        --query "policies[?policyName=='$_policy_name'].policyName")

    if test x"$result" == x; then return 1; fi

    return 0
}

function get_policy_arn {
    _policy_name=$1

    POLICY_ARN=$(aws iot list-policies ${std_awscli_args} \
        --query "policies[?policyName=='$_policy_name'].policyArn")

    if test $? != 0; then return 1; fi

    return 0
}

function create_policy {
    sed -e "s/ACCOUNT_ID/${ACCOUNT_ID}/g" -e "s/REGION/${region}/g" ${POLICY_FILE} > /tmp/policy.$$.json
    
    POLICY_ARN=$(aws iot create-policy ${std_awscli_args}                     \
                     --policy-name ${POLICY_NAME}                             \
                     --policy-document file:///tmp/policy.$$.json             \
                     --query policyArn)

    if test $? != 0; then return 1; fi
    
    sleep 3 # Potential for eventual consistency issues here.
    return 0
}

function create_certificate_devmode {
    CERTIFICATE_ARN=$(aws iot create-keys-and-certificate ${std_awscli_args}  \
                          --set-as-active                                     \
                          --certificate-pem-outfile ${certificate_file}       \
                          --public-key-outfile      ${pubkey_file}            \
                          --private-key-outfile     ${privkey_file}           \
                          --query certificateArn)
    CERTIFICATE_ID=$(echo ${CERTIFICATE_ARN} | cut -f2 -d'/')
}

function link_objects {
    aws iot attach-principal-policy ${std_awscli_args}                        \
        --policy-name ${POLICY_NAME}                                          \
        --principal ${CERTIFICATE_ARN}  || return 1

    aws iot attach-thing-principal ${std_awscli_args}                         \
        --thing-name ${THING_NAME}                                            \
        --principal  ${CERTIFICATE_ARN} || return 1

    return 0
}

function create_certificate_csr {
    echo stub
}

function store_secret {
    thing_name=$1
    thing_arn=$2
    certificate_arn=$3
    certificate_file=$4
    privatekey_file=$5
    iotcore_endpoint=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --output text --query endpointAddress)
    da_endpoint=
    # make key and certificate storable
    certificate=$(base64 --wrap=0 ${certificate_file})
    privatekey=$(base64 --wrap=0 ${privatekey_file})
    secret_name="/CodeBuild/da_cred_${thing_name}"
    
    cat <<OUT > /tmp/secret_string.json
{ "thing_name" : "${thing_name}",
  "thing_arn" : "${thing_arn}",
  "certificate" : "${certificate}",
  "certificate_arn" : "${certificate_arn}",
  "privatekey" : "${privatekey}",
  "iotcore_endpoint" : "${iotcore_endpoint}",
  "da_endpoint" : "${da_endpoint}"
}
OUT

    #    secret_string=$(cat /tmp/secret_string.json)
    secret_arn=$(aws secretsmanager create-secret \
                     --secret-string file:///tmp/secret_string.json \
                     --name ${secret_name} \
                     --description "Credentials for Device Advisor" \
                     --output text --query ARN)
    echo Secret ARN: ${secret_arn}
    echo VARIABLES for AWS CODEBUILD:
    echo name: [certificate] value: [${secret_name}:certificate]
    echo name: [privatekey] value: [${secret_name}:privatekey]
    echo name: [iotcore_endpoint] value: [${secret_name}:iotcore_endpoint]
    echo name: [da_endpoint] value: [${secret_name}:da_endpoint]
}

function export_variants {
    _volatile_dir=$1
    _thing_name=$2
    _thing_arn=$3
    _policy_name=$4
    _policy_arn=$5
    _certificate_id=$6
    _certificate_arn=$7
    _export_file=${_volatile_dir}/${_thing_name}/exports

    echo "THING_NAME=${_thing_name}"            > ${_export_file}
    echo "THING_ARN=${_thing_arn}"             >> ${_export_file}
    echo "POLICY_NAME=${_policy_name}"         >> ${_export_file}
    echo "POLICY_ARN=${_policy_arn}"           >> ${_export_file}
    echo "CERTIFICATE_ID=${_certificate_id}"   >> ${_export_file}
    echo "CERTIFICATE_ARN=${_certificate_arn}" >> ${_export_file}
}

#
# Directory where all volatile artifacts reside.

mkdir -p ${volatile_dir}/${THING_NAME}

certificate_file=${volatile_dir}/${THING_NAME}/${THING_NAME}.crt.pem
pubkey_file=${volatile_dir}/${THING_NAME}/${THING_NAME}.key.pub.pem
privkey_file=${volatile_dir}/${THING_NAME}/${THING_NAME}.key.prv.pem

if test -f ${certificate_file}; then
    echo WARNING: Certificate already created in region for device, ensure you
    echo WARNING:   redeploy to physical device.
fi
if test -f ${pubkey_file}; then
    echo WARNING: Public key already created in region for device, ensure you
    echo WARNING:   redeploy to physical device.
fi
if test -f ${privkey_file}; then
    echo WARNING: Certificate created already in region for device, ensure you
    echo WARNING:   redeploy to physical device.
fi

create_certificate_devmode

if test $FORCE == 0; then
    thing_exists $THING_NAME
    if test $? == 1; then
        create_thing $THING_NAME
        if test $? == 1; then
            echo failed to create thing object.
            exit 1
        fi
    else
        get_thing_arn $THING_NAME
        if test $? == 1; then
            echo failed to fetch thing arn.
            exit 1
        fi
    fi
else
    create_thing $THING_NAME
    if test $? == 1; then
        echo failed to create thing object.
        exit 1
    fi
fi    

if test $FORCE == 0; then
    policy_exists $POLICY_NAME
    if test $? == 1; then
        create_policy $POLICY_NAME
        if test $? == 1; then
            echo failed to create policy object.
            exit 1
        fi
    else
        get_policy_arn $POLICY_NAME
        if test $? == 1; then
            echo failed to fetch policy arn.
            exit 1
        fi
    fi
else
    create_policy $POLICY_NAME
    if test $? == 1; then
        echo failed to create policy object.
        echo since you are running force, we assume that you want to reuse an existing policy.
    fi
fi

link_objects

if test ! -z ${SECRET_NAME}; then
    store_secret ${THING_NAME} ${THING_ARN} ${CERTIFICATE_ARN} ${certificate_file} ${privkey_file}
fi

export_variants "${volatile_dir}" "$THING_NAME" "$THING_ARN" "$POLICY_NAME" \
                "$POLICY_ARN" "$CERTIFICATE_ID" "$CERTIFICATE_ARN"
